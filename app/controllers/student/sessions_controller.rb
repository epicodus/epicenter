class Student::SessionsController < Devise::SessionsController

  def create
    if can?(:create, AttendanceRecord.new) && params[:pair][:email] != ''
      pair_sign_in
    elsif can?(:create, AttendanceRecord.new)
      super
      @attendance_record = AttendanceRecord.create(student: current_student)
    else
      super
    end
  end

private

  def pair_sign_in
    student = Student.find_by(email: params[:student][:email])
    pair = Student.find_by(email: params[:pair][:email])

    if student.try(:valid_password?, params[:student][:password]) && pair.try(:valid_password?, params[:pair][:password])
      attendance_records = [AttendanceRecord.find_or_initialize_by(student: student, date: Time.zone.now.to_date),
                            AttendanceRecord.find_or_initialize_by(student: pair, date: Time.zone.now.to_date)]
      attendance_records.first.pair_id = pair.id
      attendance_records.last.pair_id = student.id
      if attendance_records.all? { |record| record.save }
        sign_out student
        student_names = attendance_records.map { |attendance_record| attendance_record.student.name }
        redirect_to welcome_path, notice: "Welcome #{student_names.join(' and ')}."
      else
        sign_out student
        redirect_to :back, alert: "Something went wrong: " + attendance_records.first.errors.full_messages.join(", ")
      end
    else
      sign_out student
      redirect_to :back, alert: 'Invalid email or password.'
    end
  end
end
