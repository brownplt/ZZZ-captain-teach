class AddUserRepoToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :user_repo, index: true
  end
end
