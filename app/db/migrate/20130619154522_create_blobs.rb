class CreateBlobs < ActiveRecord::Migration
  def change
    create_table :blobs do |t|
      t.string :uid
      t.string :ref
      t.references :user, index: true
      t.string :data

      t.timestamps
    end
  end
end
