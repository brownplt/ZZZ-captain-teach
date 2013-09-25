module Grading

  GRADING_DIR="../grades/"

  def write_code_assignment(task, resource, path)
    maybe_content = Resource::lookup_resource(resource)
    if maybe_content.respond_to?(:data)
      content = maybe_content.data
    else
      return
    end

    lines = interleave(
        task[:args]["codeDelimiters"].map do |elt| elt["value"] end,
        task[:args]["parts"].map do |p| JSON.parse(content[:file])["parts"][p["value"]] end
      )
    File.open(path, "w") do |f|
      f.puts lines.join("")
    end
  end

  def write_open_response(task, resource, path)
    maybe_content = Resource::lookup_resource(resource)
    if maybe_content.respond_to?(:data)
      content = maybe_content.data
    else
      return
    end
    content = Resource::lookup_resource(resource).data
    or_part = task[:args]["parts"][0]
    string_content = JSON.parse(content[:file])["parts"][or_part["value"]]
    puts "String: #{string_content}\n"
    File.open(path, "w") do |f|
      f.puts string_content
    end
  end

  def assignment_to_dir(user, assignment)
    FileUtils.mkdir_p(GRADING_DIR)
    assignment_dir = GRADING_DIR + "#{assignment.id}/"
    FileUtils.mkdir_p(assignment_dir)
    user_dir = assignment_dir + "#{user.id}/"
    FileUtils.mkdir_p(user_dir)
    json = AssignmentController::path_to_json(user, AssignmentController::path_ref_to_path(assignment.path_ref))
    journey_dir = user_dir + json[:id]
    FileUtils.mkdir_p(journey_dir)

    json[:tasks].each do |task|
      if task[:type] == "code-assignment"
        path = task[:resources]["path"]
        write_code_assignment(task, path, user_dir + task[:id] + ".current.arr")
      elsif task[:type] == "open-response"
        path = task[:resources]["path"]
        write_open_response(task, path, user_dir + task[:id] + ".current.txt")
      end
      if task[:parts]
        task[:parts].each do |part|
          subs = Submitted.where(:user_id => user.id, :activity_id => task[:id], :submission_type => part["name"])

          if(subs.length > 2)
            $stderr.puts "Multiple submissions for the same ref and user: #{user.to_json}, #{subs}"
          end

          puts "Task: #{task}\n"
          if subs.length == 0
            puts "No submission for #{user.to_json} for #{part["name"]}\n"
          elsif task[:type] == "code-assignment"
            sub = subs[0]
            write_code_assignment(task, sub.resource, user_dir + task[:id] + "_at_" + part["name"] + ".arr")
          elsif task[:type] == "open-response"
            sub = subs[0]
            write_open_response(task, sub.resource, user_dir + task[:id] + "_at_" + part["name"] + ".txt")
          else
            $stderr.puts "Unknown task type: #{task[:type]}\n"
          end
        end
      end
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

  module_function :assignment_to_dir, :interleave, :write_open_response, :write_code_assignment

end
