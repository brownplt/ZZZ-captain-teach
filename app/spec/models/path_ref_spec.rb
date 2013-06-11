require 'spec_helper'

describe PathRef do

  before(:all) do
    @TMPDIR = "/tmp/path_ref_tests/"
    @test_dir = @TMPDIR + "test/"

    @test_repo = UserRepo.init_repo(@test_dir)
  end

  after(:all) do
    FileUtils.rm_r(Dir.glob(@TMPDIR))
  end



end
