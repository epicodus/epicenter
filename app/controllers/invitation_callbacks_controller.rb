class InvitationCallbacksController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    InvitationCallback.new(params)
    head :ok
  end
end
