class ResourceController < ApplicationController
  
  # NOTE(dbp): this controller handles all resource lookups. Depending
  # on the type, this may mean simple JSON stored in the database, and
  # it may mean storing text in git.

  # All resources are of the form t:r:i:u where these are:
  # t - the type of resource. currently, the only valid options
  #     are:
  #         b: Blob    - a chunk of JSON stored in the database, no versions
  #         p: Pathref - a versioned document. lookup gets latest, save
  #                      creates a new version of the document
  #         g: Gitref  - reference to a file at a specific version
  # r - the permission associated with the resource. currently, the following
  #     are valid:
  #         r: read-only. lookups are fine, anything else doesn't work
  #         rc: reading and creating are okay. updating is not
  #         rw: reading and writing is all fine.
  # i - the unique identifier for the resource, in the context of the type
  #     of resource that it is. For Blobs, this is arbitrary. For Pathrefs, this
  #     is a path to the file in the users (see next part) git repository. For
  #     Gitrefs, this is /path/to/file@sha where sha is the hash of the commit in
  #     question.
  # u - the user id for the user that has this resource. Resources only need to
  #     be unique up to the point of users (so each user can have a blob with the same
  #     unique id, for example.)

  # Database independence: One principle of these resources is that
  # nothing need be created in the database before the resource is
  # actually used by a user. So when a user loads a journey, we don't
  # have to create any of the resources until they actually start doing
  # exercises.
  
  # Security: Resources are encrypted before they are sent down the
  # wire, and decrypted here. So having stuff like permission and user
  # id is actually okay, because once the resource is created, it is
  # not possible to tamper.


  # NOTE(dbp): Having early returns makes the code a lot more straightforward.
  # So, we throw exceptions for certain return types, and render accordingly.
  class NotFound < Exception
  end
  class Invalid < Exception
  end
  class PermissionDenied < Exception
  end
  class Success < Exception
  end
  rescue_from NotFound,         :with => :not_found_render
  rescue_from Invalid,          :with => :invalid_render
  rescue_from PermissionDenied, :with => :permission_denied_render
  rescue_from Success,          :with => :success_render


  
  def lookup
    # any perm is okay, because this is read
    type,_perm,ref,user = get_resource()

    if type == 'b'
      b = Blob.find_by(user: user, ref: ref)
      if b.nil?
        not_found
      else
        render :json => b.data
      end
    elsif type == 'p'
      repo = user.user_repo
      if repo.has_file_head?(ref)
        file = repo.lookup_file_head(ref)
        render :json => {file: file}
      else
        not_found
      end
    elsif type == 'g'
      path,commit = get_commit(ref)
      repo = user.user_repo
      if repo.has_file?(commit, path)
        file = repo.lookup_file(commit, path)
        render :json => {file: file}
      else
        not_found
      end
    else
      invalid
    end
  end

  def lookup_create
    type,perm,ref,user = get_resource()
    
    if perm != "rw" and perm != "rc"
      permission_denied
    else
      if type == 'b'
        b = Blob.find_by(user: user, ref: ref)
        if b.nil?
          b = Blob.create!(user: user, ref: ref,
                           data: params[:data])
        end
        render :json => b.data
      elsif type == 'p'
        repo = user.user_repo
        if repo.has_file_head?(ref)
          contents = repo.lookup_file_head(ref)
        else
          # TODO(dbp): exceptions.
          repo.create_file(ref, params[:data],
                           "lookup_create",
                           DEFAULT_GIT_USER)
          contents = params[:data]
        end
        render :json => {file: contents}
      else
        # you can't create a gitref...
        invalid
      end
    end
  end
  
  def save
    type,perm,ref,user = get_resource()

    if perm != "rw" and perm != "rc"
        permission_denied
    else
      if type == 'b'
        # TODO(dbp): handle data being absent gracefully
        # (it will fail now because it isn't valid JSON)
        b = Blob.find_by(user: user, ref: ref)
        if b.nil?
          Blob.create!(user: user, ref: ref,
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
      elsif type == 'p'
        repo = user.user_repo
        if repo.has_file_head?(ref)
          if perm != "rw"
            permission_denied
          else
            # TODO(dbp): errors
            repo.update_file(ref, params[:data],
                             "save", DEFAULT_GIT_USER)
            success
          end
        else
          # TODO(dbp): errors
          repo.create_file(ref, params[:data], "save",
                           DEFAULT_GIT_USER)
          success
        end 
      else
        # you can't save a gitref
        invalid
      end
    end
  end

  def versions
    # we use perm when constructing new resources for pathrefs
    type,perm,ref,user = get_resource()

    if type == 'b'
      b = Blob.find_by(user: user, ref: ref)
      if b.nil?
        not_found
      else
        render :json => [params[:resource]]
      end
    elsif type == 'g'
      path,commit = get_commit(ref)
      if user.user_repo.has_file?(commit,path)
        render :json => [params[:resource]]
      else
        not_found
      end
    elsif type == 'p'
      repo = user.user_repo
      if repo.has_file_head?(ref)
        p = PathRef.new(:user_repo => user.user_repo, :path => ref)
        render :json => p.versions.map {|v| {time: v[:time],
            resource: mk_resource('g',perm,"#{ref}@#{v[:oid]}",user.id)}}
      else
        not_found
      end
    else
      invalid
    end
  end
  
  private

  def get_resource
    # TODO(dbp): error handling - exceptions? return types?
    type,perm,ref,uid = params[:resource].split(":")

    begin
      user = User.find(uid)
    rescue ActiveRecord::RecordNotFound => e
      not_found
    end
    
    return type,perm,ref,user
  end

  def mk_resource(type, perm, ref, uid)
    "#{type}:#{perm}:#{ref}:#{uid}"
  end

  def get_commit(ref)
    # TODO(dbp): error handling...
    path,commit = ref.split("@")

    return path,commit
  end

  def permission_denied
    raise PermissionDenied
  end
  def permission_denied_render
    render :json => {success: false}, :status => 405
  end

  def success
    raise Success
  end
  def success_render
    render :json => {success: true}, :status => 200
  end

  def not_found
    raise NotFound
  end
  def not_found_render
    render :json => {success: false}, :status => 404
  end

  def invalid
    raise Invalid
  end
  def invalid_render
    render :json => {success: false}, :status => 400
  end
end
