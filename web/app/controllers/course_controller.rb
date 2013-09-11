class CourseController < ApplicationController

  before_action :lookup_course, :only => [:show,
                                          :edit,
                                          :update,
                                          :destroy,
                                          :add_teacher,
                                          :add_student,
                                          :show_abuses]

  def index
    if current_user
      @user = current_user
      @student_courses = current_user.student_courses
      @teacher_courses = current_user.teacher_courses
    else
      redirect_to root_url
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

  def show_abuses
    course_require_teacher(@course)
    @abuses = AbuseRecord.all
  end

  def abusive_blob(abuse_record)
    data = JSON.parse(abuse_record.abuse_data)
    if data["resource"]
      if data["type"] == "review"
        type, perm, ref, args, user = Resource::parse(data["resource"])
        blob = Resource::find_blob_for_inbox(user.id, ref)
        blob_data = JSON.parse(blob.data)
        blob_data
      elsif data["type"] == "feedback"
        type, perm, ref, args, user = Resource::parse(data["resource"])
        blob = Resource::find_blob_for_inbox(user.id, ref)
        blob_data = JSON.parse(blob.data)
        blob_data
      end
    else
      false
    end
  end

  def abusive_user(abuse_record)
    data = JSON.parse(abuse_record.abuse_data)
    b = abusive_blob(abuse_record)
    if b
      if data["type"] == "review"
        the_key = b.keys.sort.select { |k|
          b[k] == data["review"]
        }
        User.find_by(:id => the_key[0].to_i)
      elsif data["type"] == "feedback"
        the_key = b.keys.sort.select { |k|
          b[k] == Resource::lookup_resource(data["review"]["feedback"]).data
        }
        #Resource::lookup_resource(data["review"]["feedback"]).data
        #b
        User.find_by(:id => the_key[0].to_i)
      end
    else
      false
    end
  end

  private


  def lookup_course
    @course = Course.find(params[:id])
  end


end
