module ReviewHelper

  def setup_review(activity_id, resource, reviewer, reviewee)
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
  end

  def update_or_start_review(r, new_review)
    email = r.review_assignment.reviewer.email
    user_dict = { email: email, name: email }
    if not r.path_ref.file_exists?
      r.path_ref.create_file(new_review, "Create", user_dict)
    else
      r.path_ref.save_file(new_review, "Update", user_dict) 
    end
  end

  def reviewer_links(r)
    {
      
    }
  end

  def reviewee_links(r)

  end

  def review_links(activity_id, resource)
    "/review/#{activity_id}/#{resource}"
  end

end
