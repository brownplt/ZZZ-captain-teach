class GitRef < ActiveRecord::Base

  belongs_to :user_repo

  def contents
    user_repo.lookup_file(self.git_oid, self.path)
  end
  
end
