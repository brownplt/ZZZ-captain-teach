class UserMailer < ActionMailer::Base
  default from: FROM_EMAIL

  def review_email(user, assignment, review)
    @user = user
    @assignment = assignment
    @review = review
    mail(to: user.email, subject: "You've got a review!")
  end

end
