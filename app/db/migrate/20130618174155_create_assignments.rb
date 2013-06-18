class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.string :uid
      t.references :path_ref

      t.timestamps
    end
  end
end
