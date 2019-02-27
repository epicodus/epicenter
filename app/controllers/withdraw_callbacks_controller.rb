class WithdrawCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    WithdrawCallback.new(params) if params[:token] == ENV['ZAPIER_SECRET_TOKEN']
    head :ok
  end
end
