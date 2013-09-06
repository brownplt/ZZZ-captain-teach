class UserMailer < ActionMailer::Base
  default from: FROM_EMAIL

  def review_email(user, assignment, step)
    @user = user
    @assignment = assignment
    @step = step
    puts "Sending mail\n\n"
    mail(to: user.email, subject: "You've got a review!").deliver
    puts "#{ActionMailer::Base.deliveries}\n"
  end

end
