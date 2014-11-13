class CertificatesController < ApplicationController
  def show
    @student = current_student
  end
end
