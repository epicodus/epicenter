class StripeCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    StripeCallback.new(params)
    head :ok
  end
end
