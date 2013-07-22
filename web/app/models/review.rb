class Review < ActiveRecord::Base
  belongs_to :review_assignment
  belongs_to :path_ref

  def self.setup_review(activity_id, resource, reviewer, reviewee)
    existing_ra = ReviewAssignment.find_by(
      :activity_id => activity_id,
      :resource => resource,
      :reviewer => reviewer,
      :reviewee => reviewee
    )
    existing_review = existing_ra.review if existing_ra

    if existing_ra.nil? or existing_review.nil?
      review_assignment = ReviewAssignment.create!(
        :activity_id => activity_id,
        :resource => resource,
        :reviewer => reviewer,
        :reviewee => reviewee
      )
      path_ref_for_review = PathRef.create!(
        :user_repo => reviewer.user_repo,
        :path => "#{REVIEWS_SUBPATH}/#{activity_id}/#{resource}/#{reviewee.id}/#{review_assignment.id}"
      )
      review = Review.create!(
        :review_assignment => review_assignment,
        :path_ref => path_ref_for_review,
        :done => false
      )
      review
    else
      existing_review
    end
  end

  def update_or_start(new_review)
    email = self.review_assignment.reviewer.email
    user_dict = { email: email, name: email }
    if not self.path_ref.file_exists?
      self.path_ref.create_file(new_review, "Create", user_dict)
    else
      self.path_ref.save_file(new_review, "Update", user_dict) 
    end
  end

  def started?
    self.path_ref.file_exists?
  end

  def contents
    if self.started?
      self.path_ref.contents
    else
      "null"
    end
  end

end
