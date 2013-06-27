class AddCurrentGitRefToEditor < ActiveRecord::Migration
  def change
    add_reference :editors, :git_ref, index: true
  end
end
