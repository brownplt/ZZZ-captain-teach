require 'spec_helper'

describe Assignment do
  TMP_PREFIX = "/tmp/captain_teach"
  TMP_PATH = TMP_PREFIX + "/assignments_tests"
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
  
  it "should create a string for uid that is different" do
    a1 = Assignment.create!(:path_ref => @path_ref)
    a2 = Assignment.create!(:path_ref => @path_ref)
    a1.uid.should_not(eq(a2.uid))
  end

  it "should require a pathref" do
    expect{
      a = Assignment.create!()
    }.to(raise_error(ActiveRecord::RecordInvalid))
  end
end
