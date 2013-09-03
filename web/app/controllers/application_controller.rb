class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def ct_current_user
    if ((Rails.env.development? or Rails.env.test?) and session[:masquerade_user])
      User.find_by(id: session[:masquerade_user])
    else
      current_user
    end
  end

  def masquerading?
    (Rails.env.development? or Rails.env.test?) and (not session[:masquerade_user].nil?)
  end

  helper_method :masquerading?


  def assignment_require_teacher(assignment)
    if !authenticated?
      application_not_found
    elsif(!assignment.course.teachers.exists?(current_user.id))
      application_not_found
    end
  end

  def course_require_teacher(course)
    if !authenticated?
      application_not_found
    elsif !course.teachers.exists?(current_user)
      application_not_found
    end
  end

  if Rails.env.production?
    rescue_from Exception, with: :render_500
  end

  def render_500
    logger.info.exception.backtrace.join("\n")
    respond_to do |format|

    end
  end

  def application_not_found(message = "Not Found")
    raise ActionController::RoutingError.new(message)
  end

end
