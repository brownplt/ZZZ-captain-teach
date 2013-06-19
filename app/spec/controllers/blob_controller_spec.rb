require 'spec_helper'

describe BlobController do
  before(:all) do
    @user = User.new()
    @user.save!()
    @b = Blob.new(:ref => "foo", :user => @user, :data => "{}")
    @b.save!()
  end

  it "GET with r, rw, or rc should succeed" do
    get :get, :resource => "r:foo:#{@user.id}", :format => :json
    response.response_code.should(eq(200))
    # provided it parses as JSON, that's good enough for us
    JSON::parse(response.body)

    get :get, :resource => "rw:foo:#{@user.id}", :format => :json
    response.response_code.should(eq(200))
    # provided it parses as JSON, that's good enough for us
    JSON::parse(response.body)

    get :get, :resource => "rc:foo:#{@user.id}", :format => :json
    response.response_code.should(eq(200))
    # provided it parses as JSON, that's good enough for us
    JSON::parse(response.body)
  end

  it "GET on unknown ref or user should fail" do
    get :get, :resource => "rw:bazfoo:#{@user.id}", :format => :json
    response.response_code.should(eq(404))

    get :get, :resource => "rw:bazfoo:#{@user.id}", :format => :json
    response.response_code.should(eq(404))
    
  end

  it "PUT with rw should succeed" do
    put :put, :resource => "rw:foo:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(200))
    resp = JSON::parse(response.body)
    resp["success"].should(be_true)
    @b.reload()
    d = JSON::parse(@b.data)
    d.should(be_a(Array))
    d[0].should(eq(1))
  end

  it "PUT with rc or r should fail" do
    put :put, :resource => "rc:foo:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(405))

    put :put, :resource => "r:foo:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(405))
  end

  it "PUT on non-existent resource should fail" do
    put :put, :resource => "rw:bazbar:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(404))
  end

  it "POST with rc or rw with new resource should succeed" do
    post :post, :resource => "rc:bar1:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(200))
    Blob.find_by(user: @user, ref: "bar1").should(be_a(Blob))

    post :post, :resource => "rw:bar2:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(200))
    Blob.find_by(user: @user, ref: "bar2").should(be_a(Blob))
  end

  it "POST with rc or rw with existing resource should fail" do
    post :post, :resource => "rw:foo:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(405))
    
    post :post, :resource => "rc:foo:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(405))
  end

  it "POST with r should fail" do
    post :post, :resource => "r:bar1:#{@user.id}", :data => "[1]",
      :format => :json
    response.response_code.should(eq(405))
  end
  
end
