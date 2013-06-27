class CreateEditors < ActiveRecord::Migration
  def change
    create_table :editors do |t|
      t.references :path_ref, index: true
      t.string :title
      t.string :uid

      t.timestamps
    end
  end
end
