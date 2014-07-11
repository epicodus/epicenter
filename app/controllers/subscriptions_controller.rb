class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  def new
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.create(subscription_params.merge(user: current_user))
    unless @subscription.save
      flash[:alert] = 'Something went wrong. Please try again.'
      render :new
    end
  end

private

  def subscription_params
    params.require(:subscription).permit(:account_uri, :verification_uri)
  end
end
