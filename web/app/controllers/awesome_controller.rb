class AwesomeController < ApplicationController

  def become_user
    if (Rails.env.development? or Rails.env.test?)
      user = User.find_by(:id => params[:uid])
      login_browserid user.email
      head :ok
    end
  end

  def all_users
    if (Rails.env.development? or Rails.env.test?)
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

end
