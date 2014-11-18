class BalancedCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    BalancedCallback.new(params)
    render nothing: true
  end
end
