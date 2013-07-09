class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def ct_current_user
    # NOTE(dbp): this should _only_ work for administrator-type users,
    # or it needs to be very locked down.
    if session[:masquerade_user]
      User.find_by(id: session[:masquerade_user])
    else
      current_user
    end
  end

  def masquerading?
    not session[:masquerade_user].nil?
  end

  helper_method :masquerading?
  
end
