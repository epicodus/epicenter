class AttendanceSignOutClassroomController < ApplicationController
  before_action :redirect_if_not_in_classroom
  before_action :redirect_if_invalid_credentials, only: [:create]

  def create
    student = Student.find_by(email: params[:email].downcase)
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: student)
    if attendance_record
      authorize! :update, attendance_record
      if attendance_record.update(attendance_record_params)
        message_line_2 = current_student ? "<br>Don't forget to sign out of <a href='/'>Epicenter</a> as well!" : ''
        if Time.zone.now.in_time_zone(student.course.office.time_zone) < student.course.end_time_today - 15.minutes
          redirect_to sign_out_path, alert: "Goodbye #{attendance_record.student.name}. You have signed out early! If this was a mistake, just sign out again at the end of class." + message_line_2
        else
          redirect_to sign_out_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated. Please remember to shut down your computer." + message_line_2
        end
      else
        return fail("Something went wrong: " + attendance_record.errors.full_messages.join(", "))
      end
    else
      redirect_back(fallback_location: root_path, alert: "You haven't signed in yet today.")
    end
  end

private
  def attendance_record_params
    params.permit(:signing_out, :student_id)
  end

  def redirect_if_not_in_classroom
    if !IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      redirect_back(fallback_location: root_path, alert: "Attendance sign out unavailable. If you are an online student, please sign out through Epicenter.")
    end
  end

  def redirect_if_invalid_credentials
    student = Student.find_by(email: params[:email].downcase)
    return fail('Invalid email or password') unless student.try(:valid_password?, params[:password])
  end

  def fail(message)
    flash[:alert] = message
    @email = params[:email]
    render :new
  end
end
