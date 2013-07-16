class AwesomeController < ApplicationController

  def become_user
    user = User.find_by(:id => params[:uid])
    login_browserid user.email
    head :ok
  end

  def all_users
    users = User.all()
    users_json = [] 
    users.each do |u|
      users_json << {
        id: u.id,
        email: u.email
      }
    end
    render :json => users, :status => 200
  end

end
