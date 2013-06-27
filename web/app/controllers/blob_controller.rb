class BlobController < ApplicationController
  
  def lookup
    # any perm is okay, because this is read
    _perm,ref,uid = get_resource()

    b = Blob.find_by(user_id: uid, ref: ref)
    if b.nil?
      not_found
    else
      render :json => b.data
    end
  end

  def lookup_create
    perm,ref,uid = get_resource()
    
    if perm != "rw" and perm != "rc"
      permission_denied
    else
      b = Blob.find_by(user_id: uid, ref: ref)
      if b.nil?
        b = Blob.create!(user_id: uid, ref: ref,
                         data: params[:data])
      end
      render :json => b.data
    end
  end
  
  def save
    perm,ref,uid = get_resource()
    
    if perm != "rw" and perm != "rc"
      permission_denied
    else
      # TODO(dbp): handle data being absent gracefully
      # (it will fail now because it isn't valid JSON)
      b = Blob.find_by(user_id: uid, ref: ref)
      if b.nil?
        Blob.create!(user_id: uid, ref: ref,
                     data: params[:data])
        success
      else
        if perm != "rw"
          permission_denied
        else
          # TODO(dbp): handle case this isn't there
          b.data = params[:data]
          b.save! # will validate JSON
          success
        end
      end
    end
  end
  
  private

  def get_resource
    # TODO(dbp): error handling - exceptions? return types?
    perm,ref,uid = params[:resource].split(":")

    return perm,ref,uid
  end

  def permission_denied
    render :json => {success: false}, :status => 405
  end

  def success
    render :json => {success: true}, :status => 200
  end

  def not_found
    render :json => {success: false}, :status => 404
  end
end

