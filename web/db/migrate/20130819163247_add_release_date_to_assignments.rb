class AddReleaseDateToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :release, :datetime
  end
end
