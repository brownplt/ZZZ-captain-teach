class CreateGitRefs < ActiveRecord::Migration
  def change
    create_table :git_refs do |t|
      t.references :repo
      t.string :hash
      t.string :path

      t.timestamps
    end
  end
end
