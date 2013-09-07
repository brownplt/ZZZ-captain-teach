require 'spec_helper'

describe UserMailer do
  describe 'review_email' do
    it "should send mail" do
      address = "mail_test_user_good@example.com"
      user = User.create!(:email => address)
      mail = UserMailer.review_email(user, "some-assignment-id", "test-cases")
      mail.subject.should == "You've got a review!"
      mail.to.should == [address]
      mail.from.should == [FROM_EMAIL]
    end

    it "shouldn't send mail for folks configured to not send mail" do
      address = "mail_test_user_good@example.com"
      user = User.create!(:email => address, :send_email => false)
      mail = UserMailer.review_email(user, "some-assignment-id", "test-cases")
      expect(mail).to(be_instance_of(ActionMailer::Base::NullMail))
    end
  end
end


