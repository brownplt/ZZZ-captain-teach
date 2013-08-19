class CourseController < ApplicationController

  before_action :lookup_course, :only => [:show,
                                          :edit,
                                          :update,
                                          :destroy,
                                          :add_teacher,
                                          :add_student]

  def index
    if current_user
      @student_courses = current_user.student_courses
      @teacher_courses = current_user.teacher_courses
    else
      @student_courses = []
      @teacher_courses = []
    end
  end

  def show
    course_require_teacher(@course)
  end

  def new
  end

  def create
    title = params[:title]
    c = Course.create!(:title => title)
    redirect_to course_path(c)
  end

  def edit
    course_require_teacher(@course)
  end

  def update
    course_require_teacher(@course)
  end

  def destroy
    course_require_teacher(@course)
  end

  def add_teacher
    course_require_teacher(@course)
    t = User.find_by(:email => params[:email])
    if t.nil?
      # FIXME(dbp): actually say what went wrong
      application_not_found
    end
    @course.teachers << t
    redirect_to course_path(@course)
  end

  def add_student
    course_require_teacher(@course)
    s = User.find_by(:email => params[:email])
    if s.nil?
      # FIXME(dbp): actually say what went wrong
      application_not_found
    end
    @course.students << s
    redirect_to course_path(@course)
  end

  private

  def lookup_course
    @course = Course.find(params[:id])
  end


end
