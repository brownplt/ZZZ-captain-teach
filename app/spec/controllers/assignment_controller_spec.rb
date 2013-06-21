require 'spec_helper'

describe AssignmentController do
  it "should 404 on invalid uid" do
    u = User.create!
    get :lookup_assignment, :uid => "NotAValidUid",
        :user_id => 1
    response().response_code.should(eq(404))
  end
end
