class Review < ActiveRecord::Base
  belongs_to :review_assignment
  belongs_to :path_ref
end
