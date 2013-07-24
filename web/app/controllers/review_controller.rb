class ReviewController < ApplicationController

  # NOTE(joe, 22 July 2013): Currently used in Scribble/HTML pathway
  def self.reviewer_links(r)
    {
      save: "/review/save/#{r.id}",
      lookup: "/review/lookup/#{r.id}"
    }
  end

  def self.reviewee_links(r)
    {
      lookup: "/review/lookup/#{r.id}"
    }
  end

  def lookup
    r = Review.find(params[:rid])
    render :json => r.contents, :status => 200
  end

  def save
    r = Review.find(params[:rid])
    if current_user.id != r.review_assignment.reviewer.id
      application_not_found
    else
      review = params[:data]
      # Stored XSS point, make sure it parses as JSON with 'review', escaping
      # needs to happen on the other end
      parsed = nil
      begin
        parsed = JSON.parse(review)
      rescue Exception
        application_not_found("Bad JSON: #{review}")
      end
      if (not parsed.nil?) and (not parsed["review"].nil?)
        to_save = JSON.dump(parsed)
        r.update_or_start(to_save)
        r.done = true
        r.save!
        render :json => to_save, :status => 200
      else
        application_not_found("Bad JSON: #{review}")
      end
    end
  end

end

