class AttendanceRecordsController < ApplicationController
  def index
    @student = Student.find(params[:student_id])
    @attendance_days = Kaminari.paginate_array(@student.courses.non_internship_courses.total_class_days_until(Time.zone.now.to_date)).page(params[:page]).per(15)
    authorize! :manage, @student
  end
end
