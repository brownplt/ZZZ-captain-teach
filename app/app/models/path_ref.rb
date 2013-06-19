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
    user_repo.lookup_file_head(self.path)
  end

  def save_file(contents, message, user)
    raise NoSuchFile.new(self.path) unless file_exists?
    user_repo.update_file(self.path, contents, message, user)
  end

  def create_temporary
    name = File.basename(self.path)
    tmp = Tempfile.new(name)
    tmp.write(contents)
    tmp.seek(0)
    tmp
  end

end

