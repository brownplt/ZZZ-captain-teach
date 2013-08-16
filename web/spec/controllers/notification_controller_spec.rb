require 'spec_helper'

describe NotificationController do

  before(:each) do
    @user = User.create!(:email => "notification_spec#{User.count}@foo.com")
  end
  after(:each) do
    @user.destroy
  end

  it "should handle reporting abuse" do
    controller.login_browserid @user.email

    data = {
        "abuse_data" => {
          "resource" => Resource::mk_resource("b","r","feedback",{},5),
          "type" => "feedback",
          "data" => {
            "comments" => "You suck",
            "helpfullnesss" => -2
          }
        }
      }

    post :report_abuse, :abuse_data => data, :format => :json

    ar = AbuseRecord.last
    ar.user.should(eq(@user))
    JSON.parse(ar.abuse_data).should(eq(data))

  end

end
