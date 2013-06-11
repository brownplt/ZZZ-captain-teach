class PathRef < ActiveRecord::Base

  class FileExists < Exception
    attr :path
    def initialize(path)
      super
      @path = path
    end
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

end

