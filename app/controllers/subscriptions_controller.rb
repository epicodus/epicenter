class SubscriptionsController < ApplicationController
  def new
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new(subscription_params)
    if @subscription.save
      if @subscription.create_verification
        render 'sign_up_message'
      else
        redirect_to :back, notice: 'Something went wrong. Please try again.'
      end
    end
  end

private

  def subscription_params
    params.require(:subscription).permit(:account_uri, :verification_uri)
  end
end
