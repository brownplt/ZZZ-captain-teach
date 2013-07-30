class AddReviewCountToSubmitted < ActiveRecord::Migration
  def change
    add_column :submitteds, :review_count, :integer, :default => 0
  end
end
