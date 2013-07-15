class CourseController < ApplicationController

  before_action :lookup_course, :only => [:show,
                                          :edit,
                                          :update,
                                          :destroy,
                                          :add_teacher,
                                          :add_student]

  # NOTE(dbp): whether someone is a teacher or not depends
  # upon the course, so we look that up first.
  before_action :require_teacher, :only => [:show,
                                            :edit,
                                            :update,
                                            :destroy,
                                            :add_teacher,
                                            :add_student]

  def show    
  end

  def new    
  end

  def create
    title = params[:title]
    c = Course.create!(:title => title)
    redirect_to course_path(c)
  end

  def edit

  end

  def update

  end

  def destroy

  end

  def add_teacher
    t = User.find_by(:email => params[:email])
    if t.nil?
      # FIXME(dbp): actually say what went wrong
      application_not_found
    end
    @course.teachers << t
    redirect_to course_path(@course)
  end

  def add_student
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

  
  def require_teacher
    if !@course.teachers.exists?(current_user)
      application_not_found
    end
  end
  
end
