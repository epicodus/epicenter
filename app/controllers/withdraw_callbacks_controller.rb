class WithdrawCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    if params[:token] == ENV['ZAPIER_SECRET_TOKEN']
      WithdrawCallback.new(params)
      head :ok
    else
      head 404
    end
  end
end
