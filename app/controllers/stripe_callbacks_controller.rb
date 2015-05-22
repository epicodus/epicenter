class StripeCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    StripeCallback.new(params)
    render nothing: true
  end
end
