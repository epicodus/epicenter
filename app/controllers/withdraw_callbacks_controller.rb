class WithdrawCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    if params[:token] == ENV['ZAPIER_SECRET_TOKEN']
      begin
        WithdrawCallback.new(params)
      rescue ActiveRecord::RecordNotFound
        render json: {:status => 200, :error => "User not found"} and return
      end
      head :ok
    else
      head 404
    end
  end
end
