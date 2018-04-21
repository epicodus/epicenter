class PaymentCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    PaymentCallback.new(params)
    head :ok
  end
end
