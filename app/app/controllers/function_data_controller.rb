class FunctionDataController < ApplicationController


  def show
    fd = FunctionData.find(params[:id])
    render :json => fd
  end
  
  def create
    params.require(:ref)
    params.require(:user_id)
    fd = FunctionData.new(params.permit(:header,
                                        :check_block,
                                        :definition))
    if !fd.save()
      render :json => {
        :response => "Could not save FunctionData",
        :type => "error",
        :errors => fd.errors.full_messages
      }
    else
      render :json => {
        :response => "Saved FunctionData",
        :type => "success",
        :id => fd.id
      }
    end
  end

  def update
    fd = FunctionData.find(params[:id])
    fd.update_attributes(params.permit(:header,
                                       :check_block,
                                       :definition))

    if !fd.save()
      render :json => {
        :response => "Could not save FunctionData",
        :type => "error",
        :errors => fd.errors.full_messages
      }
    else
      render :json => {
        :response => "Saved FunctionData",
        :type => "success",
        :id => fd.id
      }
    end
  end

end

