class User < ActiveRecord::Base

  belongs_to :user_repo
  has_many :notifications

  has_and_belongs_to_many :teacher_courses,
    :class_name => "Course",
    :join_table => "teachers_courses"

  has_and_belongs_to_many :student_courses,
    :class_name => "Course",
    :join_table => "students_courses"

  after_create :create_user_repo
  before_destroy :delete_user_repo

  def is_staff
    self.role == "staff" or self.role == "admin"
  end

  def make_staff
    self.role = "staff"
  end

  def unmake_staff
    if self.role == "staff"
      self.role = ""
    end
  end

  def is_admin
    self.role == "admin"
  end

  def enable_email
    self.send_email = true
  end

  def disable_email
    self.send_email = false
  end

  private

  def create_user_repo
    repo = UserRepo.init_repo(File.expand_path(self.id.to_s,
                                               USER_GIT_REPO_PATH))
    self.user_repo = repo
    self.save!
  end

  def delete_user_repo
    FileUtils.rm_rf(self.user_repo.path)
  end

end
