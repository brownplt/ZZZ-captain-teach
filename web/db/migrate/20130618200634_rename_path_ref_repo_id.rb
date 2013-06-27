class RenamePathRefRepoId < ActiveRecord::Migration
  def change
    rename_column :path_refs, :repo_id, :user_repo_id
  end
end
