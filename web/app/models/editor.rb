class Editor < ActiveRecord::Base
  belongs_to :path_ref
  belongs_to :git_ref

  before_create :add_uid

  def current_git_oid()
    if self.git_ref.nil?
      self.path_ref.user_repo.repo.head.target
    else
      self.git_ref.git_oid
    end
  end

  private
  
  def add_uid()
    self.uid = Digest::MD5.hexdigest(UUIDTools::UUID.random_create.to_s)
  end

  
end
