class UserController < ApplicationController

  def index
    if (current_user.nil? or !current_user.is_admin)
      application_not_found
    end

    @users = User.all
  end

  def make_staff
    user = User.find(params[:id])
    if !user.is_staff
      user.make_staff
      user.save!
    end
    redirect_to user_index_path
  end

  def unmake_staff
    user = User.find(params[:id])
    if user.is_staff
      user.unmake_staff
      user.save!
    end
    redirect_to user_index_path
  end

end
