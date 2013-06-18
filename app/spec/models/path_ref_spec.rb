require 'spec_helper'

describe PathRef do

  before(:all) do
    @TMPDIR = "/tmp/path_ref_tests/"
    @test_dir = @TMPDIR + "test/"

    Dir.mkdir(@TMPDIR)

    @test_repo = UserRepo.init_repo(@test_dir)

    @test_file1 = "assignment1.arr"
    @test_file2 = "assignment2.arr"
    @test_file3 = "assignment3.arr"
    @test_file4 = "assignment4.arr"
    @test_file5 = "assignment5.arr"
    @test_file_exists = "assignment_exists.arr"

    @user = { :name => "Joe", :email => "joe@foobar.com" }
    @test_repo.create_file(
      @test_file_exists,
      "#commentary",
      "Comment commit",
      @user)
  end

  after(:all) do
    FileUtils.rm_r(Dir.glob(@TMPDIR))
  end

  it "should be constructible even if the path does not exist (yet)" do
    pr = PathRef.new(:user_repo => @test_repo, :path => @test_file1)
    pr.path.should(eq(@test_file1))
    pr.user_repo.should(equal(@test_repo))
    pr.file_exists?.should(equal(false))
  end

  it "should be constructible if the path does exist" do
    pr = PathRef.new(:user_repo => @test_repo, :path => @test_file_exists)
    pr.path.should(eq(@test_file_exists))
    pr.user_repo.should(equal(@test_repo))
    pr.file_exists?.should(equal(true))
  end

  it "should create the file if it does not exist" do
    pr = PathRef.new(:user_repo => @test_repo, :path => @test_file2)
    test_str = "data List: | empty end"
    commit_before = pr.user_repo.repo.last_commit
    pr.create_file(test_str, "creating", @user)
    commit_after = pr.user_repo.repo.last_commit
    pr.contents().should(eq(test_str))
    commit_before.should_not(eq(commit_after))
    commit_after.message.should(eq("creating"))
  end

  it "should error on creation if the file already exists" do
    pr = PathRef.new(:user_repo => @test_repo, :path => @test_file3)
    test_str = "data List: | empty end"
    commit_before = pr.user_repo.repo.last_commit
    pr.create_file(test_str, "creating", @user)
    commit_between = pr.user_repo.repo.last_commit

    expect {
      pr.create_file(test_str, "creating again", @user)
    }.to(raise_error(PathRef::FileExists))
    commit_final = pr.user_repo.repo.last_commit
    commit_final.should(eq(commit_between))
  end

  it "should error when saving files that do not already exist" do
    pr = PathRef.new(:user_repo => @test_repo, :path => @test_file4)
    test_str = "this is my proggy"
    expect { pr.save_file(test_str, "", @user) }.to(raise_error(PathRef::NoSuchFile))
  end

  it "should save existing files" do
    pr = PathRef.new(:user_repo => @test_repo, :path => @test_file5)
    test_str = "this is my first proggy"
    test_str2 = "this is my second proggy"
    commit1 = pr.user_repo.repo.last_commit
    pr.create_file(test_str, "creating", @user)
    commit2 = pr.user_repo.repo.last_commit
    pr.save_file(test_str2, "updating for new program", @user)
    commit3 = pr.user_repo.repo.last_commit
    pr.contents.should(eq(test_str2))
    commit1.should_not(eq(commit2))
    commit2.should_not(eq(commit3))
    commit1.should_not(eq(commit3))
    commit3.message.should(eq("updating for new program"))
  end

  it "should create temporary files" do
    pr = PathRef.new(:user_repo => @test_repo, :path => @test_file_exists)
    tmp = pr.create_temporary
    tmp.read(nil).should(eq(pr.contents))
    tmp.path.should(include("exist"))
  end

end

