class SignaturesController < ApplicationController
  include SignatureUpdater

  protect_from_forgery except: [:create]

  def new(signature_model)
    update_signature_request
    if current_student.signed?(signature_model)
      redirect_to root_path
      flash[:alert] = "You've already signed this document."
    else
      signature = signature_model.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller = signature_model.name.underscore
    end
  end

  def create
    render json: { response: 'Hello API Event Received' }
  end
end
