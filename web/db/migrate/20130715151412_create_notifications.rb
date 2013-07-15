class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :user, index: true
      t.string :message
      t.string :action

      t.timestamps
    end
  end
end
