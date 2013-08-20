class SetDefaultSubmittedKnown < ActiveRecord::Migration
  def change
    change_column :submitteds, :known, :string, :default => "unknown"
    change_column :submitteds, :known, :string, :null => false
  end
end
