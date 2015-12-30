class AttendanceSignOutsController < ApplicationController
  def new

  end

  def create
    if params[:commit] == "Sign Out"
      student = Student.find_by(email: params[:email])
      if student.valid_password?(params[:password])
        attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: student)
        authorize! :update, attendance_record
        if attendance_record.update(attendance_record_params)
          flash[:notice] = "Goodbye #{attendance_record.student.name}"
          redirect_to sign_out_path
        else
          flash[:alert] = "Something went wrong: " + attendance_record.errors.full_messages.join(", ")
          render 'attendance_sign_outs/new'
        end
      end
    end
  end

  private

    def attendance_record_params
      params.permit(:signing_out, :student_id)
    end
end
