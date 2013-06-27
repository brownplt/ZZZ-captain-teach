class CreatePathRefs < ActiveRecord::Migration
  def change
    create_table :path_refs do |t|
      t.references :repo
      t.string :path

      t.timestamps
    end
  end
end
