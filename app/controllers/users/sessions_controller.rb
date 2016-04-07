class Users::SessionsController < Devise::SessionsController
  before_filter :redirect_if_logged_in

  def create
    params[:user][:email] = params[:user][:email].downcase
    user = User.find_by(email: params[:user][:email])
    if user.try(:valid_password?, params[:user][:password])
      if user.is_a? Student
        sign_in_student(user)
      else
        sign_in_admin_or_company(user)
      end
    else
      super
    end
  end

private

  def redirect_if_logged_in
    redirect_to after_sign_in_path_for(current_user) if current_user
  end

  def sign_in_admin_or_company(user)
    if user.is_a? Admin
      request.env["devise.mapping"] = Devise.mappings[:admin]
    elsif user.is_a? Company
      request.env["devise.mapping"] = Devise.mappings[:company]
    end
    sign_in user
    redirect_to root_path, notice: 'Signed in successfully.'
  end

  def sign_in_student(user)
    request.env["devise.mapping"] = Devise.mappings[:student]
    if is_weekday? && IpLocation.is_local_computer?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip) && params[:pair][:email] != ''
      sign_in_pairs
    else
      sign_in_solo_student(user)
    end
  end

  def sign_in_solo_student(user)
    sign_in user
    if is_weekday? && IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip) && !user.signed_in_today?
      AttendanceRecord.create(student: user)
      redirect_to welcome_path, notice: 'Signed in successfully and attendance record created.'
    else
      redirect_to root_path, notice: 'Signed in successfully.'
    end
  end

  def sign_in_pairs
    sign_out_all_scopes
    @users = [Student.find_by(email: params[:user][:email]),
             Student.find_by(email: params[:pair][:email])]
    if @users.all? { |user| valid_credentials(user) }
      sign_in_pairs_with_valid_credentials
    else
      flash.now[:alert] = 'Invalid email or password.'
      self.resource = Student.new
      render 'devise/sessions/new'
    end
  end

  def sign_in_pairs_with_valid_credentials
    sign_out(current_student)
    if create_attendance_records(@users)
      student_names = @users.map { |user| user.name }.uniq
      redirect_to welcome_path, notice: "Welcome #{student_names.join(' and ')}. Your attendance records have been created."
    else
      flash.now[:alert] = "Something went wrong: " + attendance_records.first.errors.full_messages.join(", ")
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
      record.save
    end
  end
end
