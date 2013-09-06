class UserController < ApplicationController
  

  def index
    check_admin()
    @users = User.all
  end

  def make_staff
    check_admin()
    if (current_user.nil? or !current_user.is_admin)
      application_not_found
    end
    user = User.find(params[:id])
    if !user.is_staff
      user.make_staff
      user.save!
    end
    redirect_to user_index_path
  end

  def unmake_staff
    check_admin()
    user = User.find(params[:id])
    if user.is_staff
      user.unmake_staff
      user.save!
    end
    redirect_to user_index_path
  end

  def set_send_email
    if params[:send_email]
      current_user.enable_email
    else
      current_user.disable_email
    end
    current_user.save!
    redirect_to course_index_path
  end

  private

  def check_admin
    if (current_user.nil? or !current_user.is_admin)
      application_not_found
    end
  end

end
