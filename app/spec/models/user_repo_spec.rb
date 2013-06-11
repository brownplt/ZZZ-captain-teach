require 'spec_helper'

describe UserRepo do

  before(:all) do
    @TMPDIR = "/tmp/user_repo_tests/"
    @dir_with_git = @TMPDIR + "test_git_dir/"
    @dir_with_bad_git = @TMPDIR + "test_bad_git_dir/"
    @dir_without_git = @TMPDIR + "test_not_git_dir/"
    @dir_to_create = @TMPDIR + "test_git_create/"
    @dir_to_create2 = @TMPDIR + "test_git_create2/"
    @dir_to_create3 = @TMPDIR + "test_git_create3/"
    @bogus_dir = @TMPDIR + "test_bogus_dir/"

    Dir.mkdir(@TMPDIR)

    Dir.mkdir(@dir_with_bad_git)
    Rugged::Repository.init_at(@dir_with_bad_git, :bare)

    Dir.mkdir(@dir_without_git)

    @test_repo = UserRepo.init_repo(@dir_with_git)
  end

  after(:all) do
    FileUtils.rm_r(Dir.glob(@TMPDIR))
  end

  it "should access an existing repo" do
    urepo = UserRepo.new(:path => @dir_with_git)
    urepo.repo.should(be_an_instance_of(Rugged::Repository))
    urepo.repo.path.should(eq(@dir_with_git))
    urepo.repo.last_commit.should(eq(@test_repo.repo.last_commit))
  end

  it "should error if the directory does not exist" do
    expect { UserRepo.new(:path => @bogus_dir) }.to(
      raise_error(UserRepo::NoSuchDirectory)
    )
  end

  it "should error if the directory is not a repository" do
    expect { UserRepo.new(:path => @dir_without_git) }.to(
      raise_error(UserRepo::NotAGitRepo)
    )
  end

  it "should create the repo and the user repo" do
    ur = UserRepo.init_repo(@dir_to_create)
    ur.should(be_an_instance_of(UserRepo))
    ur.repo.should(be_an_instance_of(Rugged::Repository))
    ur.repo.path.should(eq(@dir_to_create))
  end

  it "should return a valid Repository for a valid path" do
    repo = UserRepo._get_repo(@dir_with_git)
    repo.should(be_an_instance_of(Rugged::Repository))
  end

  it "should create a repo" do
    repo = UserRepo._create_repo(@dir_to_create2)
    repo.should(be_an_instance_of(Rugged::Repository))
    repo.path.should(eq(@dir_to_create2)) 
  end

  it "should create files by making a new commit" do
    # must create a file first, so that there is a last commit to compare
    @test_repo.create_file("arbitrary-file", "arby", "arbitrary-file", {:email => "dbpatter@cs.brown.edu", :name => "Franklin Roosevelt"})
    last_commit_before = @test_repo.repo.last_commit
    @test_repo.create_file("program.arr", "2 + 2", "Arithmetrix", 
      {:email => "joe@cs.brown.edu", :name => "Teddy Roosevelt"})
    last_commit_after = @test_repo.repo.last_commit

    expect(last_commit_after).to_not(eq(last_commit_before))
    expect(last_commit_after.parents).to(include(last_commit_before))
  end

  it "should fail when creating existing files" do
    @test_repo.create_file("captain-init", "something", "Blah", {:email => "dbpatter@cs.brown.edu", :name => "Franklin Roosevelt"})
    expect { @test_repo.create_file("captain-init", "2 + 2", "Arithmetrix", 
      {:email => "joe@cs.brown.edu", :name => "Teddy Roosevelt"}) }
      .to(raise_error( UserRepo::PathExists ))
  end

  it "should error on a completely blank repository" do
    expect { UserRepo.new(:path => @dir_with_bad_git)}.to(
      raise_error(UserRepo::BadGitRepo))
  end

  it "should get files that exist" do
    @test_repo.create_file("about/readme.txt",
                           "Pyret roxx!",
                           "Initial commit",
                           {:email => "dbpatter@cs.brown.edu",
                            :name => "DBP"})
    contents = @test_repo.lookup_file_head("about/readme.txt")
    expect(contents).to(eq("Pyret roxx!"))
  end

  it "should tell you when files do not exist" do
    expect {
      @test_repo.lookup_file_head("__this_file_does_not_exist")
    }.to(raise_error(UserRepo::PathDoesNotExist))
  end

  describe "should update and handle old versions" do
    before(:all) do
      user = {:email => "mflatt@", :name => "Matthew"}
      @first_commit = 
        @test_repo.create_file("src/inner_workings.rkt",
                               "(dynamic-require 'implementation)",
                               "Initial commit",
                               user)
      @test_repo.update_file("src/inner_workings.rkt",
                             "(dynamic-require 'better-implementation)",
                             "Tweaks",
                             user)
      @test_repo.update_file("src/outer_workings.rkt",
                             "(require/provide 'inner-workings.rkt')",
                             "Interface",
                             user)
    end
    it "should actually update the file" do
      contents = @test_repo.lookup_file_head("src/inner_workings.rkt")
      contents.should(eq("(dynamic-require 'better-implementation)")) 
    end
    it "should give back old versions" do
      contents = @test_repo.lookup_file(@first_commit, "src/inner_workings.rkt")
      contents.should(eq("(dynamic-require 'implementation)"))
    end
    it "should complain when files don't exist in old versions" do
      expect {
        @test_repo.lookup_file(@first_commit, "src/outer_workings.rkt")
      }.to(raise_error(UserRepo::PathDoesNotExist))
    end
  end
end

