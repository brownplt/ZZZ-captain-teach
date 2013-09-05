class ChangeStringToTextForPostgres < ActiveRecord::Migration
  def change
    change_table :abuse_records do |t|
      t.change :abuse_data, :text
    end
    change_table :blobs do |t|
      t.change :ref, :text
      t.change :data, :text
    end
    change_table :git_refs do |t|
      t.change :path, :text
    end
    change_table :inbox_read_events do |t|
      t.change :ref, :text 
      t.change :resource, :text
    end
    change_table :notifications do |t|
      t.change :message, :text
      t.change :action, :text
    end
    change_table :path_refs do |t|
      t.change :path, :text
    end
    change_table :review_assignments do |t|
      t.change :activity_id, :text
      t.change :resource, :text
    end
    change_table :submitteds do |t|
      t.change :activity_id, :text
      t.change :resource, :text
    end
    change_table :user_repos do |t|
      t.change :path, :text
    end
  end
end
