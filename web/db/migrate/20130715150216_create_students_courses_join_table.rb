class CreateStudentsCoursesJoinTable < ActiveRecord::Migration
  def change
    create_table :students_courses, :id => false do |t|
      t.integer :user_id
      t.integer :course_id
    end
  end
end
