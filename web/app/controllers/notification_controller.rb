class NotificationController < ApplicationController

  def report_abuse
    if authenticated?
      abuse_data = params[:abuse_data]
      AbuseRecord.create!(:user => current_user, :abuse_data => abuse_data)
      render :json => {success: true}, :status => 200
      # TODO(joe): send emails
    else
      application_not_found
    end
  end


end
