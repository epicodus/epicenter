class SignaturesController < ApplicationController
  include SignatureUpdater

  protect_from_forgery except: [:create]

  def new(signed_signature_model, signature_model, controller_for_next_page, controller_action)
    update_signature_request
    if current_student.signed?(signature_model)
      redirect_to root_path
      flash[:alert] = "You've already signed this document."
    elsif current_user.signed?(signed_signature_model)
      signature = signature_model.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller_for_next_page = controller_for_next_page
      @controller_action = controller_action
    end
  end

  def create
    render json: { response: 'Hello API Event Received' }
  end
end
