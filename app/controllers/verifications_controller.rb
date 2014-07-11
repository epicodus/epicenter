class VerificationsController < ApplicationController
  before_action :authenticate_user!
  
  def edit
  end

  def update
    verification_uri = current_user.subscription.verification_uri
    verification = Verification.fetch(verification_uri)
    begin
      verification.confirm(params[:first_deposit], params[:second_deposit])
      current_user.subscription.update(verified: true)
      redirect_to current_user, notice: 'Thank you! Your account has been confirmed.'
    rescue
      flash[:alert] = 'Authentication amounts do not match. Please try again.'
      render :edit
    end
  end
end
