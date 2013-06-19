require 'spec_helper'

describe Blob do
  before(:all) do
    User.create()
    @user = User.last()
    @ref = "foo"
    @b = Blob.new(:user => @user, :ref => @ref, :data => "{}")
    @b.save()
  end
  
  it "should be able to be looked up by ref and user" do
    Blob.find_by(user: @user, ref: @ref).
      should(eq(@b))
  end

  it "shouldn't allow invalid json to be saved" do
    @b.data = "foo; bar"
    expect{
    @b.save!
    }.to(raise_error(ActiveRecord::RecordInvalid))
  end

  it "should create a uid when it is created" do
    c = Blob.new(:user => @user, :ref => @ref, :data => "")
    c.uid.should(be_nil)
    c.save!
    c.uid.should_not(be_nil)
  end
  
end

