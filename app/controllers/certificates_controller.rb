class CertificatesController < ApplicationController
  def show
    authorize! :read, :certificate
    @student = current_student
  end
end
