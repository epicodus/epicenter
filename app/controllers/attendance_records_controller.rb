class AttendanceRecordsController < ApplicationController
  authorize_resource

  def index
    @students = current_admin.current_cohort.students.order(:name)
  end

  def create
    @attendance_record = AttendanceRecord.new(attendance_record_params)
    if @attendance_record.save
      flash[:notice] = "Welcome #{@attendance_record.student.name}"
      flash[:secure] =  view_context.link_to("Not you?",
                        attendance_record_path(@attendance_record),
                        data: {method: :delete})
      redirect_to attendance_path
    else
      flash[:alert] = "Something went wrong: " + @attendance_record.errors.full_messages.join(", ")
      redirect_to attendance_path
    end
  end

  def update
    @attendance_record = AttendanceRecord.find(params[:id])
    if @attendance_record.update(attendance_record_params)
      redirect_to attendance_path, notice: "#{@attendance_record.student.name} successfully updated."
    else
      flash[:alert] = "Something went wrong: " + @attendance_record.errors.full_messages.join(", ")
      redirect_to attendance_path
    end
  end

  def destroy
    @attendance_record = AttendanceRecord.find(params[:id])
    @attendance_record.destroy
    redirect_to attendance_path, alert: "Attendance record has been deleted."
  end

private

  def attendance_record_params
    params.require(:attendance_record).permit({:attendance_record => {:signing_out => true}}, :student_id)
  end
end
