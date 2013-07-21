require 'nokogiri' # NOTE(dbp): may require gem install nokogiri

class AssignmentController < ApplicationController

  def get_assignment
    assignment = Assignment.find_by(:uid => params[:uid])
    if assignment.nil?
      application_not_found
    else
      if !authenticated?
        @html = "Not logged in"
      else
        @html = path_ref_to_html(ct_current_user, assignment.path_ref)
      end
    end
  end

  def grade_assignment
    assignment = Assignment.find_by(:uid => params[:uid])
    if assignment.nil?
      application_not_found("No such assignment")
    else
      if !authenticated?
        @html = "Not logged in"
      else
        if(assignment.course.teachers.exists?(current_user.id))
          user = User.find(params[:user_id])
          @html = path_ref_to_grade_html(user, assignment.path_ref)
        else
          application_not_found("No access to assignment")
        end
      end
    end
  end

  private

  def path_ref_to_html(user, path_ref)
    scribbled = Scribble::render(path_ref)
    doc = Nokogiri::HTML(scribbled)
    main = doc.css('div.main').first
    if main.nil?
      # NOTE(dbp): a scribble doc without a main div is bad.
      raise Scribble::ScribbleError, scribbled
    end
    
    main.css("[data-ct-node='1']").each do |node|
      if node["data-resources"]
        resources = JSON.parse(node["data-resources"])
        resources.keys.each do |k|
          # add user credentials and encrypt
          resources[k] = Resource::mk_user_resource(resources[k], user.id)
        end
        node["data-resources"] = resources.to_json
      end
    end
    main.to_html
  end

  def path_ref_to_grade_html(user, path_ref)
    scribbled = Scribble::render(path_ref)
    doc = Nokogiri::HTML(scribbled)
    main = doc.css('div.main').first
    if main.nil?
      # NOTE(dbp): a scribble doc without a main div is bad.
      raise Scribble::ScribbleError, scribbled
    end
    
    main.css("[data-ct-node='1']").each do |node|
      if node["data-resources"]
        resources = JSON.parse(node["data-resources"])
        reviews = {}
        resources.keys.each do |k|
          # add user credentials and encrypt
          resources[k] = Resource::read_only(Resource::mk_user_resource(resources[k], user.id))
          review = Review.setup_review(node["data-activity-id"], resources[k], current_user, user)
          print("\n\nkey: #{k}\n\n")
          print("\n\nreviews: #{resources[:reviews]}\n\n")
          reviews[k] = ReviewController.reviewer_links(review)
        end
        resources[:reviews] = reviews
        node["data-resources"] = resources.to_json
        # TODO(joe): how to remove?
        node["data-activity-id"] = "_"
      end
    end
    main.to_html
  end
  
end

