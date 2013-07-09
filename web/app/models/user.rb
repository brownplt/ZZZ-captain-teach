class User < ActiveRecord::Base

  belongs_to :user_repo

  after_create :create_user_repo
  before_destroy :delete_user_repo
  
  private

  def create_user_repo
    repo = UserRepo.init_repo(File.expand_path(self.id.to_s,
                                               USER_GIT_REPO_PATH))
    self.user_repo = repo
    self.save!
  end

  def delete_user_repo
    FileUtils.rm_rf(self.user_repo.path)
  end
  
end
