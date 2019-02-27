class WithdrawCallback
  include ActiveModel::Model

  def initialize(params)
    email = params[:email]
    student = Student.with_deleted.find_by(email: email)
    student.try(:destroy)
  end
end
