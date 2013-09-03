class ResourceController < ApplicationController
  
  # NOTE(dbp): this controller handles all resource lookups. Depending on the
  # type, this may mean simple JSON stored in the database, and it may mean
  # storing text in git.  See lib/resources.rb for the heavy lifting

  class NotFound < Exception
  end
  rescue_from NotFound,         :with => :not_found_render
  def not_found_render
    render :json => {success: false}, :status => 404
  end

  def lookup
    # any perm is okay, because this is read
    type,_perm,ref,args,user = get_resource()
    if (type == 'inbox-for-read')
      InboxReadEvent.create!(:user => user, :current_user_id => ct_current_user, :resource => params[:resource], :ref => ref)
    end
    Resource::lookup(type, _perm, ref, args, user).respond(self)
  end

  def lookup_create
    type,perm,ref,args,user = get_resource()
    Resource::lookup_create(type, perm, ref, args, user, params[:data]).respond(self)
  end
  
  def save
    type,perm,ref,args,user = get_resource()
    Resource::save(type, perm, ref, args, user, params[:data]).respond(self)
  end

  def versions
    # we use perm when constructing new resources for pathrefs
    type,perm,ref,args,user = get_resource()
    Resource::versions(type, perm, ref, args, user, params[:resource]).respond(self)
  end

  def submit
    # any perm is okay, because this is read
    type,_perm,ref,args,user = get_resource()
    Resource::submit(type, _perm, ref, args, user, params[:data], params[:resource]).respond(self)
  end
  
  private

  def get_resource
    # TODO(dbp): error handling - exceptions? return types?
    parsed = Resource::parse(params[:resource])
    if parsed
      return parsed
    else
      raise NotFound
    end
  end

end
