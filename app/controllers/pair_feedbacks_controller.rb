class PairFeedbacksController < ApplicationController
  authorize_resource

  def index
    @student = Student.find(params[:student_id])
    authorize! :manage, Course
  end

  def new
    @student = current_student
    authorize! :read, @student
    if @student.attendance_records.today.any?
      @pairs_without_feedback = @student.pairs_without_feedback_today
      @pair_feedback = PairFeedback.new
    else
      redirect_back(fallback_location: root_path, alert: "You haven't signed in yet today.")
    end
  end

  def create
    @student = current_student
    if @student.pairs_without_feedback_today.any?
      @pair_feedback = PairFeedback.new(pair_feedback_params)
      if @pair_feedback.save
        if @student.pairs_without_feedback_today.any?
          redirect_to sign_out_path
        else
          sign_out_student
        end
      else
        @pairs_without_feedback = @student.pairs_without_feedback_today
        render :new
      end
    else
      sign_out_student
    end
  end

private
  def pair_feedback_params
    params.require(:pair_feedback).permit(:pair_id, :q1_response, :q2_response, :q3_response, :comments).merge(student_id: current_student.id)
  end

  def sign_out_student
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: current_student)
    authorize! :update, attendance_record
    attendance_record.signing_out = true
    if attendance_record.save
      redirect_to root_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated."
    else
      redirect_to root_path, alert: attendance_record.errors.full_messages.join(", ")
    end
  end
end
