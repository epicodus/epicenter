class SignaturesController < ApplicationController
  include SignatureParamsHelper

  protect_from_forgery except: [:create]

  def new(signed_signature_model, signature_model, controller_for_next_page)
    check_signature_params
    if current_user.signed?(signed_signature_model)
      signature = signature_model.create(student_id: current_student.id)
      @sign_url = signature.sign_url
      @controller_for_next_page = controller_for_next_page
    else
      redirect_to root_path
    end
  end

  def create
    response = JSON.parse(params['json'])
    event_type = response['event']['event_type']
    if event_type == 'signature_request_signed'
      signature_request_id = response['signature_request']['signature_request_id']
      signature = Signature.find_by(signature_request_id: signature_request_id)
    end
  end
end
