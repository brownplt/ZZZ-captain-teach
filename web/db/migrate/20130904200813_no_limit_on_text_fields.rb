class NoLimitOnTextFields < ActiveRecord::Migration
  def change
    change_table :abuse_records do |t|
      t.change :abuse_data, :text, :limit => nil
    end
    change_table :blobs do |t|
      t.change :ref, :text, :limit => nil
      t.change :data, :text, :limit => nil
    end
    change_table :git_refs do |t|
      t.change :path, :text, :limit => nil
    end
    change_table :inbox_read_events do |t|
      t.change :ref, :text, :limit => nil
      t.change :resource, :text, :limit => nil
    end
    change_table :notifications do |t|
      t.change :message, :text, :limit => nil
      t.change :action, :text, :limit => nil
    end
    change_table :path_refs do |t|
      t.change :path, :text, :limit => nil
    end
    change_table :review_assignments do |t|
      t.change :activity_id, :text, :limit => nil
      t.change :resource, :text, :limit => nil
    end
    change_table :submitteds do |t|
      t.change :activity_id, :text, :limit => nil
      t.change :resource, :text, :limit => nil
    end
    change_table :user_repos do |t|
      t.change :path, :text, :limit => nil
    end
  end
end
