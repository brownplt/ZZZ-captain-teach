class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  def lookup_user
    if !params[:user_id]
      # NOTE(dbp): this is a hack, only to be used until we do actual
      # user authentication. Then use cookies, etc.
      params[:user_id] = 1
    end
    @current_user = User.find(params[:user_id])
  end
  
end
