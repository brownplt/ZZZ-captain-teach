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


  belongs_to :user_repo, :foreign_key => :repo_id

  attr_accessor :path, :user_repo

  def file_exists?
    user_repo.has_file_head?(@path)
  end

  def create_file(contents, user)
    raise FileExists.new(@path) if file_exists?
    user_repo.create_file(@path, contents, "File created", user)
  end

  def contents
    user_repo.lookup_file_head(@path)
  end

  def save_file(contents, message, user)
    raise NoSuchFile.new(@path) unless file_exists?
    user_repo.update_file(@path, contents, message, user)
  end

end

