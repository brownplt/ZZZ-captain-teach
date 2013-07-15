require 'spec_helper'

describe ResourceController do
  before(:all) do
    @user = User.create!(email: "edward@captainteach.org")
    @b = Blob.new(:ref => "foo", :user => @user, :data => "{}")
    @b.save!()

    @file = "blah"
    @user.user_repo.create_file("foo", @file,
                                "message", DEFAULT_GIT_USER)
  end

  describe "Blobs" do

    it "GET lookup with r, rw, or rc should succeed" do
      get :lookup, :resource => "b:r:foo:#{@user.id}", :format => :json
      response.response_code.should(eq(200))
      # provided it parses as JSON, that's good enough for us
      JSON::parse(response.body)

      get :lookup, :resource => "b:rw:foo:#{@user.id}", :format => :json
      response.response_code.should(eq(200))
      # provided it parses as JSON, that's good enough for us
      JSON::parse(response.body)

      get :lookup, :resource => "b:rc:foo:#{@user.id}", :format => :json
      response.response_code.should(eq(200))
      # provided it parses as JSON, that's good enough for us
      JSON::parse(response.body)
    end

    it "GET on unknown ref or user should fail" do
      get :lookup, :resource => "b:rw:bazfoo:#{@user.id}", :format => :json
      response.response_code.should(eq(404))

      get :lookup, :resource => "b:rw:bazfoo:not-an-id", :format => :json
      response.response_code.should(eq(404))
      
    end

    it "POST with rw should succeed" do
      post :save, :resource => "b:rw:foo:#{@user.id}", :data => "[1]",
      :format => :json
      response.response_code.should(eq(200))
      resp = JSON::parse(response.body)
      resp["success"].should(be_true)
      @b.reload()
      d = JSON::parse(@b.data)
      d.should(be_a(Array))
      d[0].should(eq(1))
    end

    it "POST with rc when the item exists should fail" do
      post :save, :resource => "b:rc:foo:#{@user.id}", :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "POST with r should fail" do
      post :save, :resource => "b:r:foo:#{@user.id}", :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "POST with rc or rw with new resource should succeed" do
      post :save, :resource => "b:rc:bar1:#{@user.id}", :data => "[1]",
      :format => :json
      response.response_code.should(eq(200))
      Blob.find_by(user: @user, ref: "bar1").should(be_a(Blob))

      post :save, :resource => "b:rw:bar2:#{@user.id}", :data => "[1]",
      :format => :json
      response.response_code.should(eq(200))
      Blob.find_by(user: @user, ref: "bar2").should(be_a(Blob))
    end

    it "POST with r should fail" do
      post :save, :resource => "b:r:bar1:#{@user.id}", :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "GET versions should succeed for existing blob" do
      resource = "b:r:foo:#{@user.id}"

      get :versions, :resource => resource, :format => :json
      response.response_code.should(eq(200))
      v = JSON::parse(response.body)
      v.should(be_a(Array))
      v.should(eq([{"time"=>"", "resource"=>resource}]))
    end

    it "GET versions should 404 on non-existent blob" do
      get :versions, :resource => "b:rw:bar3:#{@user.id}", :format => :json
      response.response_code.should(eq(404))
    end
  end

  describe "PathRef" do
    it "GET with r, rc, or rw should succeed" do
      get :lookup, :resource => "p:r:foo:#{@user.id}", :format => :json
      response.response_code.should(eq(200))
      JSON::parse(response.body)["file"].should(eq(@file))

      get :lookup, :resource => "p:rw:foo:#{@user.id}", :format => :json
      response.response_code.should(eq(200))
      JSON::parse(response.body)["file"].should(eq(@file))
      
      get :lookup, :resource => "p:rc:foo:#{@user.id}", :format => :json
      response.response_code.should(eq(200))
      JSON::parse(response.body)["file"].should(eq(@file))
    end

    it "GET on unknown ref or user should fail" do
      get :lookup, :resource => "p:rw:bazfoo:#{@user.id}", :format => :json
      response.response_code.should(eq(404))

      get :lookup, :resource => "p:rw:foo:not-an-id", :format => :json
      response.response_code.should(eq(404))
    end

    it "POST with rw should succeed" do
      @user.user_repo.create_file("foo1", @file,
                                "message", DEFAULT_GIT_USER)
      
      path_ref = PathRef.new(:user_repo => @user.user_repo, :path => "foo1")
      before_versions = path_ref.versions.length
      new_data = "My New File"
      post :save, :resource => "p:rw:foo1:#{@user.id}", :data => new_data,
      :format => :json
      response.response_code.should(eq(200))
      resp = JSON::parse(response.body)
      resp["success"].should(be_true)
      
      path_ref.contents.should(eq(new_data))
      path_ref.versions.length.should(eq(before_versions + 1))
    end
    
    it "POST with rc when the item exists should fail" do
      post :save, :resource => "p:rc:foo:#{@user.id}", :data => "Blah blah blah",
      :format => :json
      response.response_code.should(eq(405))
    end
    
    it "POST with r should fail" do
      post :save, :resource => "p:r:foo:#{@user.id}", :data => "[1]",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "POST with rc or rw with new resource should succeed" do
      data = "My Program"
      post :save, :resource => "p:rc:bar1:#{@user.id}", :data => data,
      :format => :json
      response.response_code.should(eq(200))
      @user.user_repo.lookup_file_head("bar1").should(eq(data))

      data2 = "My Program 2"
      post :save, :resource => "p:rw:bar2:#{@user.id}", :data => data2,
      :format => :json
      response.response_code.should(eq(200))
      @user.user_repo.lookup_file_head("bar2").should(eq(data2))
    end

    it "POST with r should fail" do
      post :save, :resource => "p:r:bar3:#{@user.id}", :data => "Baz",
      :format => :json
      response.response_code.should(eq(405))
    end

    it "GET versions should succeed for existing pathref" do
      resource = "p:r:foo:#{@user.id}"

      get :versions, :resource => resource, :format => :json
      response.response_code.should(eq(200))
      v = JSON::parse(response.body)
      v.should(be_a(Array))
    end

    it "GET versions should 404 on non-existent pathref" do
      get :versions, :resource => "p:rw:bar3:#{@user.id}", :format => :json
      response.response_code.should(eq(404))
    end

    it "GET versions should return all versions of pathref" do
      post :save, :resource => "p:rw:bar4:#{@user.id}", :data => "Program 1",
      :format => :json
      post :save, :resource => "p:rw:bar4:#{@user.id}", :data => "Program 2",
      :format => :json
      post :save, :resource => "p:rw:bar4:#{@user.id}", :data => "Program 3",
      :format => :json

      get :versions, :resource => "p:rw:bar4:#{@user.id}", :format => :json
      puts response.body
      resp = JSON::parse(response.body)
      resp.should(be_a(Array))
      resp.length.should(eq(3))
    end

    it "GET versions should return gitrefs to old versions of the pathref" do
      data1 = "Program 1"
      post :save, :resource => "p:rw:bar5:#{@user.id}", :data => data1,
      :format => :json
      data2 = "Program 2"
      post :save, :resource => "p:rw:bar5:#{@user.id}", :data => data2,
      :format => :json

      get :versions, :resource => "p:rw:bar5:#{@user.id}", :format => :json
      resp = JSON::parse(response.body)
      resp.should(be_a(Array))
      resp.length.should(eq(2))

      get :lookup, :resource => resp[0]["resource"], :format => :json
      resp1 = JSON::parse(response.body)
      resp1["file"].should(eq(data2))

      get :lookup, :resource => resp[1]["resource"], :format => :json
      resp1 = JSON::parse(response.body)
      resp1["file"].should(eq(data1))
    end
  end
  
end
