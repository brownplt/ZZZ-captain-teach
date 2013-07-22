class PathRef < ActiveRecord::Base

  

  class PathException < Exception
    attr :path
    def initialize(path)
      super
      @path = path
    end
  end

  class FileExists < PathException
  end

  class NoSuchFile < PathException
  end

  belongs_to :user_repo

  has_many :assignment

  def file_exists?
    user_repo.has_file_head?(self.path)
  end

  def create_file(contents, message, user)
    raise FileExists.new(self.path) if file_exists?
    user_repo.create_file(self.path, contents, message, user)
  end

  def contents
    if Rails.env.development?
      p = File.expand_path(self.path, user_repo.path)
      if File.exists?(p)
        File.open(p).gets(nil)
      else
        user_repo.lookup_file_head(self.path)
      end
    else
      user_repo.lookup_file_head(self.path)
    end
  end

  def save_file(contents, message, user)
    raise NoSuchFile.new(self.path) unless file_exists?
    user_repo.update_file(self.path, contents, message, user)
    dirty_versions
  end

  def create_temporary
    name = File.basename(self.path)
    tmp = Tempfile.new(name)
    tmp.write(contents)
    tmp.seek(0)
    tmp
  end

  def versions
    # NOTE(joe): cache was borked on 07/03/2013
    # vs = Rails.cache.read({:path_ref => self.id})
    vs = nil
    if vs.nil?
      repo = self.user_repo.repo
      walker = Rugged::Walker.new(repo)
      walker.push(repo.last_commit)
      revisions = []
      # we walk backwards, so the previous commit is newer
      prev = repo.last_commit
      # NOTE(dbp): this will never include the first commit
      # of the repository, but that's okay, because we initialize
      # the repository with a blank commit
      walker.each do |commit|
        if prev != commit # bootstrapping, only true once
          diff = prev.diff(commit, {:paths => [self.path]})
          if diff.size != 0
            # diff between commit and prev is non-empty, so
            # prev (newer) added changes.
            revisions.push({:oid => prev.oid, :time => prev.time})
          end
          prev = commit
        end
      end
      vs = revisions
      Rails.cache.write({:path_ref => self.id}, vs)
    end
    vs
  end

  private
  
  # simple caching
  def dirty_versions
    Rails.cache.delete({:path_ref => self.id})
  end
  
end

