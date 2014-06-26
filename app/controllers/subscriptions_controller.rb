class SubscriptionsController < ApplicationController
  def new
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new(subscription_params)
    current_user.subscription = @subscription
    if @subscription.save && @subscription.create_verification
      render 'sign_up_message'
    else
      redirect_to :back, notice: 'Something went wrong. Please try again.'
    end
  end

  def edit
    @subscription = Subscription.find(params[:id])
  end

  def update
    @subscription = Subscription.find(params[:id])
    if @subscription.update(subscription_params)
      redirect_to current_user, notice: 'Thank you! Your account has been confirmed.'
    else
      render :edit
    end
  end

private

  def subscription_params
    params.require(:subscription).permit(:account_uri, :verification_uri, :first_deposit, :second_deposit)
  end
end
