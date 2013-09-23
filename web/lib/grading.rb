module Grading

  GRADING_DIR="../grades/"

  def assignment_to_dir(user, assignment)
    FileUtils.mkdir_p(GRADING_DIR)
    assignment_dir = GRADING_DIR + "#{assignment.id}/"
    FileUtils.mkdir_p(assignment_dir)
    user_dir = assignment_dir + "#{user.id}/"
    FileUtils.mkdir_p(user_dir)
    json = AssignmentController::path_to_json(user, AssignmentController::path_ref_to_path(assignment.path_ref))

    json.each do |task|
      if task[:parts]
        task[:parts].each do |part|
          subs = Submitted.where(:user_id => user.id, :activity_id => task[:id], :submission_type => part["name"])

          if(subs.length > 2)
            $stderr.puts "Multiple submissions for the same ref and user: #{user.to_json}, #{subs}"
          end

          if subs.length == 0
            puts "No submission for #{user.to_json} for #{part["name"]}\n"
          elsif task[:type] == "code-assignment"
            sub = subs[0]
            content_at_time = Resource::lookup_resource(sub.resource).data
            lines = interleave(
                task[:args]["codeDelimiters"].map do |elt| elt["value"] end,
                task[:args]["parts"].map do |p| JSON.parse(content_at_time[:file])["parts"][p["value"]] end
              )
            File.open(user_dir + part["name"] + ".arr", "w") do |f|
              f.puts lines.join("")
            end
          elsif task[:type] == "open-response"
            sub = subs[0]
            content_at_time = Resource::lookup_resource(sub.resource).data
            or_part = task[:args]["parts"][0]
            string_content = JSON.parse(content_at_time[:file])["parts"][or_part["value"]]
            File.open(user_dir + part["name"] + ".arr", "w") do |f|
              f.puts string_content
            end
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

  module_function :assignment_to_dir, :interleave

end
