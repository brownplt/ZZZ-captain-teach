class SessionsController < ApplicationController

  # POST /login
  def create
    # NOTE(dbp): pulled out of gem and customized to create users.
    if params[:assertion].blank?
      head :bad_request
    else
      email, issuer, audience = verify_browserid params[:assertion]
      logger.info "Verified BrowserID assertion for #{email} issued by #{issuer} on #{audience}"
      login_browserid email
      if current_user.nil?
        User.create!(email: email)
      end
      head :ok
    end
  rescue StandardError => e
    Airbrake.notify(e)
    # TODO: distinguish between process failures and invalid assertions
    logger.warn "Failed to verify BrowserID assertion: #{e.message}"
    render status: :forbidden, text: e.message
  end

  # POST /logout
  def destroy
    logout_browserid
    head :ok
  end

end
