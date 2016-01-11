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
    @users = [Student.find_by(email: params[:student][:email]),
             Student.find_by(email: params[:pair][:email])]

    if @users.all? { |user| valid_credentials(user) }
      sign_out(current_student)
      if create_attendance_records(@users)
        student_names = @users.map { |user| user.name }.uniq
        redirect_to welcome_path, notice: "Welcome #{student_names.join(' and ')}."
      else
        flash[:alert] = "Something went wrong: " + attendance_records.first.errors.full_messages.join(", ")
        self.resource = Student.new
        render 'devise/sessions/new'
      end
    else
      sign_out(current_student)
      redirect_to new_student_session_path, alert: 'Invalid email or password.'
    end
  end

  def valid_credentials(student)
    if student == @users.first
      student.try(:valid_password?, params[:student][:password])
    else
      student.try(:valid_password?, params[:pair][:password])
    end
  end

  def create_attendance_records(users)
    users.map do |user|
      record = AttendanceRecord.find_or_initialize_by(student: user, date: Time.zone.now.to_date)
      record.pair_id = (users - [user]).try(:first).try(:id)
      record.save
    end
  end
end
