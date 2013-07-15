class AddCourseToAssignments < ActiveRecord::Migration
  def change
    add_reference :assignments, :course, index: true
  end
end
