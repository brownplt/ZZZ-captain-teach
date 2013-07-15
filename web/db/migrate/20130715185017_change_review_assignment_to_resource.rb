class ChangeReviewAssignmentToResource < ActiveRecord::Migration
  def change
    remove_column :review_assignments, :path
    remove_column :review_assignments, :commit
    add_column :review_assignments, :resource, :string
  end
end
