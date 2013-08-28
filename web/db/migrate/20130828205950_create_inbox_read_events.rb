class CreateInboxReadEvents < ActiveRecord::Migration
  def change
    create_table :inbox_read_events do |t|
      t.string :ref
      t.references :user, index: true

      t.timestamps
    end
  end
end
