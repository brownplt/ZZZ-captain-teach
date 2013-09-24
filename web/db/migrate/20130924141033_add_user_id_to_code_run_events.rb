class AddUserIdToCodeRunEvents < ActiveRecord::Migration
  def change
    add_reference :code_run_events, :user
  end
end
