class CreateUserRepos < ActiveRecord::Migration
  def change
    create_table :user_repos do |t|
      t.string :path

      t.timestamps
    end
  end
end
