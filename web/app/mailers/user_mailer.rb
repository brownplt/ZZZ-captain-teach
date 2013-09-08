class UserMailer < ActionMailer::Base
  default from: FROM_EMAIL

  def review_email(user, assignment_id, step)
    begin
      if SEND_EMAIL and user.send_email and not (user.send_email.nil?)
        @assignment_id = assignment_id
        @step = step
        mail(to: user.email, subject: "You've got a review!").deliver
      end
    rescue => ex
      Airbrake.notify(ex)
      ActionMailer::Base::NullMail.new
    end
  end

end
