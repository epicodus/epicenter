class PairFeedbacksController < ApplicationController
  authorize_resource

  def index
    @student = Student.find(params[:student_id])
    authorize! :manage, Course
  end

  def new
    @student = current_student
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: @student)
    if attendance_record
      pair1 = @student.pair_on_day(Time.zone.now.to_date)
      pair2 = @student.pair2_on_day(Time.zone.now.to_date)
      if pair2 && !PairFeedback.find_by(student: @student, pair: pair2)
        @pair = pair2
        @sign_out_button_text = 'Continue to next pair feedback'
      else
        @pair = pair1
        @sign_out_button_text = 'Attendance sign out'
      end
      @pair_feedback = PairFeedback.new
      authorize! :read, @student
    else
      redirect_back(fallback_location: root_path, alert: "You haven't signed in yet today.")
    end
  end

  def create
    @student = current_student
    if @student.pair_on_day(Time.zone.now.to_date)
      @pair_feedback = PairFeedback.new(pair_feedback_params)
      if @pair_feedback.save
        pair1 = @student.pair_on_day(Time.zone.now.to_date)
        if !PairFeedback.find_by(student: @student, pair: pair1)
          redirect_to sign_out_path
        else
          sign_out_student
        end
      else
        @pair = Student.find(pair_feedback_params[:pair_id])
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
