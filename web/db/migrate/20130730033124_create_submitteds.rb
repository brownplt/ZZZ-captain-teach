class CreateSubmitteds < ActiveRecord::Migration
  def change
    create_table :submitteds do |t|
      t.references :user, index: true
      t.string :activity_id
      t.string :resource
      t.datetime :submission_time
      t.string :type

      t.timestamps
    end
  end
end
