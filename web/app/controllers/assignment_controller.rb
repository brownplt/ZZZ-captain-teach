require 'nokogiri' # NOTE(dbp): may require gem install nokogiri

class AssignmentController < ApplicationController

  def edit_assignment
    @assignment = Assignment.find_by(:uid => params[:uid])
    assignment_require_teacher(@assignment)
  end

  def update_assignment
    assignment = Assignment.find_by(:uid => params[:uid])
    assignment_require_teacher(@assignment)
    assignment.release = Time.local(params[:year], params[:month],
                                    params[:day], params[:hour],
                                    params[:minute])
    assignment.save!
    redirect_to edit_assignment_path(assignment.uid)
  end

  def get_assignment
    assignment = Assignment.find_by(:uid => params[:uid])
    if assignment.nil?
      application_not_found
    else
      if !authenticated?
        @html = "Not logged in"
      else
        path = AssignmentController::path_ref_to_path(assignment.path_ref)
        @html = AssignmentController::path_to_html(ct_current_user, path)
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
          path = AssignmentController::path_ref_to_path(assignment.path_ref)
          @html = path_to_grade_html(user, path)
        else
          application_not_found("No access to assignment")
        end
      end
    end
  end

  def self.resource_from_dict(d, uid)
    Resource::mk_resource(
        d["type"],
        d["perms"],
        d["ref"],
        d["args"],
        uid
      )
  end

  def self.part_ref(id, k)
    "#{id}-#{k}"
  end
  def self.reviews_ref(ref)
    "#{ref}-reviews"
  end
  def self.feedback_ref(ref)
    "#{ref}-feedback"
  end

  def self.path_ref_to_path(path_ref)
    path_ref.create_temporary
  end


  def self.path_to_html(user, path)
    scribbled = Scribble::render(path)
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
          resources[k] = AssignmentController.resource_from_dict(resources[k], user.id)
        end
        node["data-resources"] = resources.to_json

        if not node["data-parts"].nil?
          parts = JSON.parse(node["data-parts"])
          activity_id = node["data-activity-id"]
          parts = parts.map do |k|
            key = k["value"]
            part_ref = AssignmentController.part_ref(activity_id, key)
            {
              name: key,
              type: k["type"],
              read_reviews: Resource::mk_resource(
                  "inbox-for-read",
                  "r",
                  part_ref,
                  {},
                  user.id
                ),
              read_feedback: Resource::mk_resource(
                  "inbox-for-read",
                  "r",
                  AssignmentController.feedback_ref(part_ref),
                  {},
                  user.id
                ),
              do_reviews: Resource::mk_resource(
                  "b",
                  "r",
                  AssignmentController.reviews_ref(
                      AssignmentController.part_ref(activity_id, key)
                    ),
                  {},
                  user.id
                )
            }
          end
          node["data-parts"] = JSON.dump(parts)
        end
      end
    end
    main.to_html
  end

  def self.path_to_json(user, path)
    html = Nokogiri::HTML(AssignmentController.path_to_html(user, path))
    html.css("[data-ct-node='1']").map do |node|
      if not node["data-parts"].nil?
        {
          resources: JSON.parse(node["data-resources"]),
          id: node["data-activity-id"],
          parts: JSON.parse(node["data-parts"]),
          args: JSON.parse(node["data-args"])
        }
      else {}
      end
    end
  end

  def path_to_grade_html(user, path)
    scribbled = Scribble::render(path)
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
          resource = Resource::read_only(resource_from_dict(resources[k], user.id))
          type, perm, ref, args, uid = Resource::parse(resource)
          versions = Resource::versions(type, perm, ref, args, uid, resource)
          resources[k] = resource
          versionsResources = []
          if versions.instance_of?(Resource::Normal)
            versionsResources = versions.data
          end
          versionsReviews = versionsResources.map { |v|
            versionReview = Review.setup_review(node["data-activity-id"], v[:resource], current_user, user)
            ReviewController.reviewer_links(versionReview)
          }
          review = Review.setup_review(node["data-activity-id"], resources[k], current_user, user)
          reviews[k] = {}
          reviews[k][:review] = ReviewController.reviewer_links(review)
          reviews[k][:versions] = versionsReviews
        end
        resources[:reviews] = reviews
        node["data-resources"] = resources.to_json
        node.delete("data-activity-id")
      end
    end
    main.to_html
  end

end
