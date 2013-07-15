class ReviewAssignment < ActiveRecord::Base
  belongs_to :reviewer
  belongs_to :reviewee
end
