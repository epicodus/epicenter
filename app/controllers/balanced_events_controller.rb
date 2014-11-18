class BalancedEventsController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    BalancedEvent.new(params)
    render nothing: true
  end
end
