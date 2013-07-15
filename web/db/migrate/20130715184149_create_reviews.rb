class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.references :review_assignment, index: true
      t.boolean :done
      t.references :path_ref, index: true

      t.timestamps
    end
  end
end
