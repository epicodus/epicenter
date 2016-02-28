class Users::SessionsController < Devise::SessionsController

  def create
    user = User.find_by(email: params[:user][:email])
    if user.try(:valid_password?, params[:user][:password])
      if user.is_a? Admin
        sign_in_admin(user)
      elsif user.is_a? Student
        request.env["devise.mapping"] = Devise.mappings[:student]
        if is_local? && params[:pair][:email] != ''
          pair_sign_in
        else
          sign_in_student(user)
        end
      end
    else
      super
    end
  end

private

  def sign_in_admin(user)
    request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in user
    redirect_to root_path, notice: 'Signed in successfully.'
  end

  def sign_in_student(user)
    sign_in user
    redirect_to root_path, notice: 'Signed in successfully.'
    if is_local?
      @attendance_record = AttendanceRecord.new(student: user)
      @attendance_record.sign_in_ip_address = request.env['HTTP_CF_CONNECTING_IP']
      @attendance_record.save
    end
  end

  def pair_sign_in
    sign_out_all_scopes

    @users = [Student.find_by(email: params[:user][:email]),
             Student.find_by(email: params[:pair][:email])]

    if @users.all? { |user| valid_credentials(user) }
      sign_out(current_student)
      if create_attendance_records(@users)
        student_names = @users.map { |user| user.name }.uniq
        redirect_to welcome_path, notice: "Welcome #{student_names.join(' and ')}."
      else
        flash.now[:alert] = "Something went wrong: " + attendance_records.first.errors.full_messages.join(", ")
        self.resource = Student.new
        render 'devise/sessions/new'
      end
    else
      flash.now[:alert] = 'Invalid email or password.'
      self.resource = Student.new
      render 'devise/sessions/new'
    end
  end

  def valid_credentials(student)
    if student == @users.first
      student.try(:valid_password?, params[:user][:password])
    else
      student.try(:valid_password?, params[:pair][:password])
    end
  end

  def create_attendance_records(users)
    users.map do |user|
      record = AttendanceRecord.find_or_initialize_by(student: user, date: Time.zone.now.to_date)
      record.pair_id = (users - [user]).try(:first).try(:id)
      record.sign_in_ip_address = request.env['HTTP_CF_CONNECTING_IP']
      record.save
    end
  end
end
