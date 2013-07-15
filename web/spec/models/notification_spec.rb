require 'spec_helper'

describe Notification do
  before(:all) do
    User.create()
    @user = User.last()
    @action = "{\"type\":\"link\",\"url\":\"http://captain/assignment/42#part4\"}"
    @message = "Reviews available on assignment 4, part 7"
    @n = Notification.new(:user => @user, :action => @action, :message => @message)
    @n.save
  end

  it "should be look-uppable by user" do
    Notification.find_by(user: @user).should(eq(@n))
  end

  it "should produce a JSON version of itself" do
    expected_json = {
      "message" => @message,
      "action" => JSON.parse(@action)
    }
    JSON.parse(@n.to_json).should(eq(expected_json))
  end

  it "should find multiple per user if they exist" do
    @n = Notification.new(:user => @user, :action => @action, :message => "duplicate")
    @n.save
    @user.notifications.length.should(eq(2))
  end
end
