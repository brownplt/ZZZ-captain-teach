module Grading

  GRADING_DIR="../grades/"

  def get_code_lines(task, resource)
    maybe_content = Resource::lookup_resource(resource)
    if maybe_content.respond_to?(:data)
      content = maybe_content.data
    else
      return
    end

    interleave(
        task[:args]["codeDelimiters"].map do |elt| elt["value"] end,
        task[:args]["parts"].map do |p| JSON.parse(content[:file])["parts"][p["value"]] end
      )
  end

  def get_open_response_string(task, resource)
    maybe_content = Resource::lookup_resource(resource)
    if maybe_content.respond_to?(:data)
      content = maybe_content.data
    else
      return
    end
    or_part = task[:args]["parts"][0]
    JSON.parse(content[:file])["parts"][or_part["value"]]
  end

  def write_code_assignment(task, resource, path)
    lines = get_code_lines(task, resource)
    return if lines.nil?
    File.open(path, "w") do |f|
      f.puts lines.join("")
    end
  end

  def write_open_response(task, resource, path)
    string_content = get_open_response_string(task, resource)
    return if string_content.nil?
    File.open(path, "w") do |f|
      f.puts string_content
    end
  end

  def write_review(path, review_text, review_target)
    File.open(path, "w") do |f|
      f.puts "Correctness: #{review_text["correctness"]}\n"
      f.puts "Correctness comments:\n\n #{review_text["correctnessComments"]}\n\n"
      f.puts "Design: #{review_text["design"]}"
      f.puts "Design comments:\n\n #{review_text["designComments"]}\n\n"

      f.puts "Reviewing: \n\n"
      f.puts review_target
    end
  end
  def write_reviews(task, do_reviews, path)
    maybe_content = Resource::lookup_resource(do_reviews)
    if maybe_content.respond_to?(:data)
      content = maybe_content.data
    else
      return
    end
    i = 0
    JSON.parse(maybe_content.data).each do |r|
      i += 1
      File.open(path + "-review-written-#{i}.txt", "w") do |f|
        if task[:type] == "code-assignment"
          review_target_text = get_code_lines(task, r["resource"]).join("")
        elsif task[:type] == "open-response"
          review_target_text = get_open_response_string(task, r["resource"])
        end

        maybe_review_text = Resource::lookup_resource(r["save_review"])
        if maybe_review_text.respond_to?(:data)
          review_text = maybe_review_text.data["review"]
          write_review(path + "-review-written-#{i}.txt", review_text, review_target_text)
          # also create a file with the submission time
          submitted = Submitted.find_by(id: r['submission_id'])
          File.open(path + "-review-submission-time-#{i}.txt", "w") do |ff|
            if submitted
              ff.puts submitted.submission_time
            else
              ff.puts ''
            end
          end
        else
          f.puts "No review found"
        end
      end
    end
  end

  def write_received_reviews(task, read_reviews, path)
    maybe_content = Resource::lookup_resource(read_reviews)
    if maybe_content.respond_to?(:data)
      content = maybe_content.data
    else
      return
    end
    i = 0
    content.each do |r|
      i += 1
      File.open(path + "-review-received-#{i}.txt", "w") do |f|
        if task[:type] == "code-assignment"
          review_target_text = get_code_lines(task, r["resource"]).join("")
        elsif task[:type] == "open-response"
          review_target_text = get_open_response_string(task, r["resource"])
        end

        review_text = r["review"]
        write_review(path + "-review-received-#{i}.txt", review_text, review_target_text)
      end
    end
  end

  def assignment_to_dir(user, assignment)
    FileUtils.mkdir_p(GRADING_DIR)
    assignment_dir = GRADING_DIR + "#{assignment.id}/"
    FileUtils.mkdir_p(assignment_dir)
    user_dir = assignment_dir + "#{user.id}/"
    FileUtils.mkdir_p(user_dir)
    File.open(user_dir + "email.txt", "w") do |f|
      f.puts user.email
    end
    json = AssignmentController::path_to_json(user, AssignmentController::path_ref_to_path(assignment.path_ref))
    journey_dir = user_dir + json[:id]
    puts "make journey_dir: #{journey_dir}"
    FileUtils.mkdir_p(journey_dir)

    json[:tasks].each do |task|
      if task[:type] == "code-assignment"
        path = task[:resources]["path"]
        write_code_assignment(task, path, user_dir + task[:id] + ".current.arr")
        write_first_viewed_time(user, task, user_dir + task[:id] + ".first-viewed-time.txt")
      elsif task[:type] == "open-response"
        path = task[:resources]["path"]
        write_open_response(task, path, user_dir + task[:id] + ".current.txt")
        write_first_viewed_time(user, task, user_dir + task[:id] + ".first-viewed-time.txt")
      end
      if task[:parts]
        task[:parts].each do |part|
          subs = Submitted.where(:user_id => user.id, :activity_id => task[:id], :submission_type => part["name"])

          if(subs.length > 2)
            $stderr.puts "Multiple submissions for the same ref and user: #{user.to_json}, #{subs}"
          end

          if subs.length == 0
            $stderr.puts "No submission for #{user.to_json} for #{part["name"]}\n"
          elsif task[:type] == "code-assignment"
            sub = subs[0]
            # TODO: can use InboxReadEvent.find_by(user: u, ref: ire_ref) to see when they read their reviews
            ##ire_ref = task[:id] + "-" + part["name"]
            write_code_assignment(task, sub.resource, user_dir + task[:id] + "_at_" + part["name"] + ".arr")
            write_submission_time(sub, user_dir + task[:id] + "_at_" + part["name"] + ".submission-time.txt")
          elsif task[:type] == "open-response"
            sub = subs[0]
            write_open_response(task, sub.resource, user_dir + task[:id] + "_at_" + part["name"] + ".txt")
          else
            $stderr.puts "Unknown task type: #{task[:type]}\n"
          end
          write_reviews(task, part["do_reviews"], user_dir + task[:id] + "_at_" + part["name"])
          write_received_reviews(task, part["read_reviews"], user_dir + task[:id] + "_at_" + part["name"])
        end
      end
    end
  end

  def write_first_viewed_time(user, task, output_filename)
      user_repo = user.user_repo
      repo = user_repo.repo
      path = task[:resources]["path"]
      # TODO: get first-viewed-time from HTTP logs. for now, it's estimated
      _type, _perms, ref, _args, _user = Resource::parse(path)

      # find earliest commit-containing-the-ref
      prev = nil  # contains the oldest commit-containging-the-ref found so far
      curr = repo.lookup(repo.head.target)  # contains the next commit to check
      while curr  # no next commit means we've checked all commits, up to the initial commit
        if user_repo.has_file?(curr.oid, ref)
          prev = curr
          curr = curr.parents[0]
        else
          break
        end
      end
      puts "border: #{curr}\t#{prev}"
      File.open(output_filename, 'w') do |f|
        if prev
          f.puts prev.time
        end
      end
  end

  def write_submission_time(submission, path)
    File.open(path, "w") do |f|
      f.puts submission.submission_time
    end
  end

  def interleave(l1, l2)
    combined = []
    i = 0
    len = l1.length
    l1.each do |elt|
      combined << elt
      if i < (len - 1)
        combined << l2.shift
      end
      i += 1
    end
    combined
  end

  module_function :assignment_to_dir, :interleave, :write_open_response, :write_code_assignment, :write_reviews, :write_submission_time, :get_code_lines, :get_open_response_string, :write_received_reviews, :write_review, :write_first_viewed_time

end
