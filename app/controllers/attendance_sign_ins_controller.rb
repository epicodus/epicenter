class AttendanceSignInsController < ApplicationController

  def new

  end

  def create
    authorize! :create, AttendanceRecord.new
    if params[:commit] == 'Solo'
      student = Student.find_by(email: params[:email_1])
      if student.valid_password?(params[:password_1])
        @attendance_record = AttendanceRecord.new(student: student)
      end
      if @attendance_record.save
        flash[:notice] = "Welcome #{@attendance_record.student.name}"
        flash[:secure] =  view_context.link_to("Not you?",
                        attendance_record_path(@attendance_record),
                        data: {method: :delete})
        redirect_to root_path
      else
        flash[:alert] = "Something went wrong: " + @attendance_record.errors.full_messages.join(", ")
        render 'attendance_sign_ins/new'
      end
    else
      attendance_records = []
      student_1 = Student.find_by(email: params[:email_1])
      student_2 = Student.find_by(email: params[:email_2])
      if student_1.valid_password?(params[:password_1])
        attendance_records << AttendanceRecord.new(student: student_1, pair_id: student_2.id)
      end
      if student_2.valid_password?(params[:password_2])
        attendance_records << AttendanceRecord.new(student: student_2, pair_id: student_1.id)
      end
      if attendance_records.all? { |record| record.save }
        student_names = attendance_records.map { |attendance_record| attendance_record.student.name }
        flash[:notice] = "Welcome #{student_names.join(' and ')}."
        flash[:secure] =  view_context.link_to("Wrong student?",
                    destroy_multiple_pair_attendance_records_path(ids: attendance_records.map(&:id)),
                    data: {method: :delete})
        redirect_to root_path
      else
        flash[:alert] = "Something went wrong: " + attendance_records.first.errors.full_messages.join(", ")
        render 'attendance_sign_ins/new'
      end
    end
  end
end
