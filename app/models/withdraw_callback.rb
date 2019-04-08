class WithdrawCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]
    student = Student.with_deleted.find_by(email: email)
    if student
      student.enrollments.destroy_all
    else
      raise ActiveRecord::RecordNotFound, "WithdrawCallback: #{email} not found"
    end
  end
end
