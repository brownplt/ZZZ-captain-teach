class Editor < ActiveRecord::Base
  belongs_to :path_ref
  belongs_to :git_ref

  before_create :add_uid

  before_update :dirty_versions

  def versions()
    if @versions.nil?
      repo = self.path_ref.user_repo.repo
      walker = Rugged::Walker.new(repo)
      walker.push(repo.last_commit)
      @versions = walker.select do |commit|
        commit.message == "editor #{self.uid}"
      end
    end
    @versions
  end

  def current_git_oid()
    if self.git_ref.nil?
      self.path_ref.user_repo.repo.head.target
    else
      self.git_ref.git_oid
    end
  end

  private

  def dirty_versions
    @versions = nil
  end
  
  def add_uid()
    self.uid = Digest::MD5.hexdigest(UUIDTools::UUID.random_create.to_s)
  end

  
end
