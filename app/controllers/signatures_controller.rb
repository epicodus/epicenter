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
      case signature_model.name
      when "CodeOfConduct"
        @controller_for_next_page = 'refund_policy'
      when "RefundPolicy"
        if current_student.course.office.name == "Seattle"
          @controller_for_next_page = 'complaint_disclosure'
        else
          @controller_for_next_page = 'enrollment_agreement'
        end
      when "ComplaintDisclosure"
        @controller_for_next_page = 'enrollment_agreement'
      when "EnrollmentAgreement"
        @controller_for_next_page = 'payment_methods'
      end
    end
  end

  def create
    render json: { response: 'Hello API Event Received' }
  end
end
