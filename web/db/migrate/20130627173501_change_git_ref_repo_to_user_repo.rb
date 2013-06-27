class ChangeGitRefRepoToUserRepo < ActiveRecord::Migration
  def change
    rename_column :git_refs, :repo_id, :user_repo_id    
  end
end
