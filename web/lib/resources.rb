module Resource

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
  # not possible to tamper. (NOTE(joe): Encryption is a TODO)

  class NotFound
    def respond(renderer)
      renderer.render :json => {success: false}, :status => 404
    end
  end
  class Invalid
    def respond(renderer)
      renderer.render :json => {success: false}, :status => 400
    end
  end
  class PermissionDenied
    def respond(renderer)
      renderer.render :json => {success: false}, :status => 405
    end
  end
  class Success
    def respond(renderer)
      renderer.render :json => {success: true}, :status => 200
    end
  end
  class Normal
    def respond(renderer)
      renderer.render :json => @data
    end
    attr_accessor :data
    def initialize(data)
      @data = data
    end
  end

  def mk_user_resource(base, uid)
    # NOTE(dbp): encrypt here
    "#{base}:#{uid}"
  end

  def mk_resource(type, perm, ref, uid)
    mk_user_resource("#{type}:#{perm}:#{ref}", uid)
  end

  def read_only(resource)
    parsed = parse(resource)
    if parsed
      type, perm, ref, uid = parsed
      mk_resource(type, 'r', ref, uid.id)
    else
      false
    end
  end

  def get_commit(ref)
    # TODO(dbp): error handling...
    path,commit = ref.split("@")

    return path,commit
  end

  def parse(resource)
    # TODO(dbp): error handling - exceptions? return types?
    type,perm,ref,uid = resource.split(":")

    begin
      user = User.find(uid)
    rescue Exception => e
      return false
    end
    
    return type,perm,ref,user
  end

  def lookup(type, _perm, ref, user)
    if type == 'b'
      b = Blob.find_by(user: user, ref: ref)
      if b.nil?
        return NotFound.new
      else
        return Normal.new(b.data)
      end
    elsif type == 'p'
      repo = user.user_repo
      if repo.has_file_head?(ref)
        file = repo.lookup_file_head(ref)
        return Normal.new({file: file})
      else
        return NotFound.new
      end
    elsif type == 'g'
      path,commit = Resource::get_commit(ref)
      repo = user.user_repo
      if repo.has_file?(commit, path)
        file = repo.lookup_file(commit, path)
        return Normal.new({file: file})
      else
        return NotFound.new
      end
    else
      return Invalid.new
    end
  end

  def lookup_create(type, perm, ref, user, data)
    
    if perm != "rw" and perm != "rc"
      return PermissionDenied.new
    else
      if type == 'b'
        b = Blob.find_by(user: user, ref: ref)
        if b.nil?
          b = Blob.create!(user: user, ref: ref,
                           data: data)
        end
        return Normal.new(b.data)
      elsif type == 'p'
        repo = user.user_repo
        if repo.has_file_head?(ref)
          contents = repo.lookup_file_head(ref)
        else
          # TODO(dbp): exceptions.
          repo.create_file(ref, data,
                           "lookup_create",
                           DEFAULT_GIT_USER)
          contents = data
        end
        return Normal.new({file: contents})
      else
        # you can't create a gitref...
        return Invalid.new
      end
    end
  end

  def save(type, perm, ref, user, data)
    if perm != "rw" and perm != "rc"
      return PermissionDenied.new
    else
      if type == 'b'
        # TODO(dbp): handle data being absent gracefully
        # (it will fail now because it isn't valid JSON)
        b = Blob.find_by(user: user, ref: ref)
        if b.nil?
          Blob.create!(user: user, ref: ref,
                       data: data)
          return Success.new
        else
          if perm != "rw"
            return PermissionDenied.new
          else
            # TODO(dbp): handle case this isn't there
            b.data = data
            b.save! # will validate JSON
            return Success.new
          end
        end
      elsif type == 'p'
        repo = user.user_repo
        if repo.has_file_head?(ref)
          if perm != "rw"
            return PermissionDenied.new
          else
            # TODO(dbp): errors
            repo.update_file(ref, data,
                             "save", DEFAULT_GIT_USER)
            return Success.new
          end
        else
          # TODO(dbp): errors
          repo.create_file(ref, data, "save",
                           DEFAULT_GIT_USER)
          return Success.new
        end 
      else
        # you can't save a gitref
        return Invalid.new
      end
    end
  end

  def versions(type, perm, ref, user, resource)
    if type == 'b'
      b = Blob.find_by(user: user, ref: ref)
      if b.nil?
        return NotFound.new
      else
        return Normal.new([{time: "", resource: resource}])
      end
    elsif type == 'g'
      path,commit = Resource::get_commit(ref)
      if user.user_repo.has_file?(commit,path)
        return Normal.new([{time: "", resource: resource}])
      else
        return NotFound.new
      end
    elsif type == 'p'
      repo = user.user_repo
      if repo.has_file_head?(ref)
        p = PathRef.new(:user_repo => user.user_repo, :path => ref)
        versions = p.versions.map {|v|
          resource = Resource::mk_resource('g',perm,"#{ref}@#{v[:oid]}",user.id)
          ro_resource = Resource::read_only(resource)
          review_assignments = ReviewAssignment.where(
            :reviewee => user,
            :resource => ro_resource
          )
          reviews = []
          review_assignments.map { |ra|
            if (not ra.review.nil?) and ra.review.done
              reviews << ReviewController.reviewee_links(ra.review)
            end
          }
          {
            time: v[:time],
            resource: resource,
            reviews: reviews
          }
        }
        return Normal.new(versions)
      else
        return NotFound.new
      end
    else
      return Invalid.new
    end
  end

  module_function :mk_resource, :mk_user_resource, :read_only, :get_commit, :parse, :lookup, :lookup_create, :save, :versions
end
