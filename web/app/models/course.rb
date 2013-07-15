class Course < ActiveRecord::Base

  has_many :assignments

  has_and_belongs_to_many :teachers,
    :class_name => "User",
    :join_table => "teachers_courses"
  
  has_and_belongs_to_many :students,
    :class_name => "User",
    :join_table => "students_courses"
  
end
