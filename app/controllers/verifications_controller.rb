class VerificationsController < ApplicationController
  before_action :authenticate_user!

  def edit
  end

  def update
    verification = Verification.new(params.merge(user: current_user))
    if verification.confirm
      redirect_to current_user, notice: 'Thank you! Your account has been confirmed.'
    else
      flash[:alert] = 'Authentication amounts do not match. Please try again.'
      render :edit
    end
  end
end
