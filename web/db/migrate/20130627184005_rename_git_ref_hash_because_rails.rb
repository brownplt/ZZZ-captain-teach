class RenameGitRefHashBecauseRails < ActiveRecord::Migration
  def change
    rename_column :git_refs, :hash, :git_oid
  end
end
