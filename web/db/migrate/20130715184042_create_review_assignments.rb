class CreateReviewAssignments < ActiveRecord::Migration
  def change
    create_table :review_assignments do |t|
      t.references :reviewer, index: true
      t.references :reviewee, index: true
      t.string :activity_id
      t.string :path
      t.string :commit

      t.timestamps
    end
    add_index :review_assignments, :activity_id
  end
end
