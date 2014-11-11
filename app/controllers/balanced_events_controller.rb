class BalancedEventsController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    binding.pry
    BalancedEvent.new(params)
    render nothing: true
  end
end

