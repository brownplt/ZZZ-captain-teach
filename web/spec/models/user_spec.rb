require 'spec_helper'

describe User do
  it "should disable and enable email" do
    u = User.create!
    u.disable_email()
    u.send_email.should(eq(false))
    u.enable_email()
    u.send_email.should(eq(true))
  end
end

