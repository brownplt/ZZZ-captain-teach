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
      scribbled = run_scribble(assignment.path_ref)
      render :json => scribbled
    end
  end
  
end
