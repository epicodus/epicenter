class UpfrontPaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.make_upfront_payment
    flash[:notice] = "Thank You! Your upfront payment has been made."
    redirect_to payments_path
  end
end
