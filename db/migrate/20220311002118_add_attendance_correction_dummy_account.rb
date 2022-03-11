class AddAttendanceCorrectionDummyAccount < ActiveRecord::Migration[5.2]
  def change
    password = SecureRandom.base64
    Student.create(email: "teacher-attendance-correction-#{ENV['FROM_EMAIL_PAYMENT']}", name: '* ATTENDANCE CORRECTION *', password: password, password_confirmation: password)
  end
end
