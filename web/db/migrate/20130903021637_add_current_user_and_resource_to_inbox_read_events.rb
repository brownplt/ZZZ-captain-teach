class AddCurrentUserAndResourceToInboxReadEvents < ActiveRecord::Migration
  def change
    add_column :inbox_read_events, :current_user_id, :integer
    add_column :inbox_read_events, :resource, :string
  end
end

