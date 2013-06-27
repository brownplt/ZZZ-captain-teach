require 'spec_helper'

describe Editor do
  TMP_PREFIX = "/tmp/captain_teach"
  TMP_PATH = TMP_PREFIX + "/editor_tests"
  TMP_REPO = TMP_PATH + "/1"
  before(:all) do
    FileUtils.mkdir_p(TMP_PATH)
    @user_repo = UserRepo.init_repo(TMP_REPO)
    @path_ref = PathRef.new(:path => "foo/bar",
                            :user_repo => @user_repo)
  end

  after(:all) do
    FileUtils.rm_r(TMP_PREFIX)
  end

  it "should create a uid when it is created" do
    c = Editor.new(:path_ref => @ref, :title => "Great program")
    c.uid.should(be_nil)
    c.save!
    c.uid.should_not(be_nil)
  end

end
