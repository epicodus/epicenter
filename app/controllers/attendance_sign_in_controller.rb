class AttendanceSignInController < ApplicationController
  before_action :authenticate_student!

  def new
    @button_text = current_student.signed_in_today? ? 'Change pair' : 'Sign in'
    @other_students = current_student.course.students_all_locations.where.not(id: current_student.id)
    @pairs_today = current_student.pairs_today
    respond_to do |format|
      format.js { render 'new' }
      format.html { redirect_to root_path, alert: 'Be sure Javascript is enabled in your browser.' }
    end
  end

  def create
    record = AttendanceRecord.find_or_initialize_by(student: current_student, date: Time.zone.now.in_time_zone(current_student.course.office.time_zone).to_date)
    if record.update(pair_ids: params[:pair_ids])
      redirect_back(fallback_location: root_path)
    else
      redirect_to root_path, alert: record.errors.full_messages.join(', ')
    end
  end
end
