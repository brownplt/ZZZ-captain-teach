class AssignmentController < ApplicationController
  before_action :lookup_user
  
  def do_assignment
    @url = "/lookup_assignment?user_id=#{@current_user.id}&uid=#{params[:uid]}"
  end

  def lookup_assignment
    begin
      assignment = Assignment.find(params[:uid])
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:code => 404,
        :message => "No such assignment"}, :status => 404
    else
      scribbled = Scribble::load(assignment.path_ref)
      scribbled_json = JSON::parse(scribbled)
      assignment_json = Commands::interp_tag(1,
                                             scribbled_json,
                                             assignment.path_ref.path)
      render :json => assignment_json
    end
  end
  
end
