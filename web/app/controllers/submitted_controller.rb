class SubmittedController < ApplicationController

  def index
    if ct_current_user.nil?
      application_not_found
    end
    @submitted = Submitted.where(:user => ct_current_user)
    @is_staff = ct_current_user.is_staff
  end

  def good
    if (ct_current_user.nil? or !ct_current_user.is_staff)
      application_not_found
    end

    submitted = Submitted.find(params[:id])
    submitted.set_good
    submitted.save!

    redirect_to submitted_index_path
  end

  def bad
    if (ct_current_user.nil? or !ct_current_user.is_staff)
      application_not_found
    end

    submitted = Submitted.find(params[:id])
    submitted.set_bad
    submitted.save!

    redirect_to submitted_index_path
  end

  def unknown
    if (ct_current_user.nil? or !ct_current_user.is_staff)
      application_not_found
    end

    submitted = Submitted.find(params[:id])
    submitted.set_unknown
    submitted.save!

    redirect_to submitted_index_path
  end

end
