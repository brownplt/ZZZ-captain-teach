
require 'nokogiri'

module ExportData

  # assignment_path is a path to a .jrny file (e.g. ct-assignments/tutorial.jrny)
  def get_student_code_activity_resources(user, assignment_path)
    scribbled = Scribble::render(assignment_path)
    doc = Nokogiri::HTML(scribbled)

    student_data_for_assignment = {}

    main = doc.css('div.main').first
    main.css("[data-ct-node='1']").each do |node|
      if node["data-type"] == "code-assignment"
        resources = JSON.parse(node["data-resources"])
        resources.keys.each do |k|
          resources[k] = 
              AssignmentController.resource_from_dict(resources[k], user.id)
        end
        args = JSON.parse(node["data-args"])
        student_data_for_assignment[node["data-activity-id"]] = {
          path_ref: resources["path"],
          args: args
        }
      end
    end
    student_data_for_assignment
  end

  def get_student_current_answer(user, activity_ref)
    type, perms, ref, args, user = Resource::parse(activity_ref)
    repo = user.user_repo
    file = "No work yet"
    if repo.has_file_head?(ref)
      file = repo.lookup_file_head(ref)
    end
    file
  end


  module_function :get_student_code_activity_resources,
                  :get_student_current_answer
end

captains_log = UserRepo.create!(:path => ASSIGNMENTS_PATH)
pr = PathRef.create!(
  :user_repo => captains_log,
  :path => "sorting.jrny"
)
path = AssignmentController::path_ref_to_path(pr)
shriram = User.find_by(:email => "shriram@gmail.com")
resources = 
  ExportData::get_student_code_activity_resources(shriram, path)
print("Shriram's resources were:")
print("#{resources}\n")
print(ExportData::get_student_current_answer(shriram, resources.values[0][:path_ref]))

