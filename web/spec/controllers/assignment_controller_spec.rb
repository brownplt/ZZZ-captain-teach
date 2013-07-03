require 'spec_helper'

describe AssignmentController do
  before(:all) do
    USER_GIT_REPO_PATH = "/tmp/ct-user-repos"
    Dir.mkdir(USER_GIT_REPO_PATH)
  end
  
  after(:all) do
    FileUtils.rm_rf(USER_GIT_REPO_PATH)
  end
  it "should 404 on invalid uid" do
    u = User.create!
    get :get_assignment, :uid => "NotAValidUid",
     :user_id => 1
    response().response_code.should(eq(404))
  end
end
