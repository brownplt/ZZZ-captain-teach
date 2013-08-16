class CreateAbuseRecords < ActiveRecord::Migration
  def change
    create_table :abuse_records do |t|
      t.references :user index: true
      t.string :abuse_data

      t.timestamps
    end
  end
end
