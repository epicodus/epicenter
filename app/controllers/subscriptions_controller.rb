class SubscriptionsController < ApplicationController
  def new
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.create(subscription_params.merge(user: current_user))
    if @subscription.save
      render 'sign_up_message'
    else
      flash[:notice] = 'Something went wrong. Please try again.'
      render :new
    end
  end

  def edit
    @subscription = current_user.subscription
  end

  def update
    @subscription = current_user.subscription
    if @subscription.update(subscription_params)
      redirect_to current_user, notice: 'Thank you! Your account has been confirmed.'
    else
      flash[:notice] = "Your account could not be confirmed."
      render :edit
    end
  end

private

  def subscription_params
    params.require(:subscription).permit(:account_uri, :verification_uri, :first_deposit, :second_deposit)
  end
end
