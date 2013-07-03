require 'spec_helper'

describe FunctionData do
  before(:all) do
    USER_GIT_REPO_PATH = "/tmp/ct-user-repos"
    Dir.mkdir(USER_GIT_REPO_PATH)
    @user = User.create!(email: "edward@captainteach.org")

    @ref = "foo"
    @fd = FunctionData.new(:user => User.last, :ref => @ref)
    @fd.save()
  end
  
  after(:all) do
    FileUtils.rm_rf(USER_GIT_REPO_PATH)
  end

  it "should be able to be looked up by ref and user" do
    FunctionData.find_by(user: @user, ref: @ref).
      should(eq(@fd))
  end

  it "should be able to save header" do
    header = "my header"
    @fd.header = header
    @fd.save()
    @fd.reload()
    @fd.header.should(eq(header))
  end

  
end
