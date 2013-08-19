class AddKnownToSubmitteds < ActiveRecord::Migration
  def change
    add_column :submitteds, :known, :string
  end
end
