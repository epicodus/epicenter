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
      if @pairs_without_feedback.any?
        @pair_feedback = PairFeedback.new
      else
        redirect_back(fallback_location: root_path, notice: 'All pair feedback has been submitted.')
      end
    else
      redirect_back(fallback_location: root_path, alert: "You haven't signed in yet today.")
    end
  end

  def create
    @student = current_student
    @pair_feedback = PairFeedback.new(pair_feedback_params)
    if @pair_feedback.save
      flash[:notice] = "Pair feedback submitted for #{@pair_feedback.pair.name}"
      if @student.pairs_without_feedback_today.any?
        redirect_to pair_feedback_path
      elsif @student.online?
        redirect_to sign_out_remote_path
      else
        redirect_to root_path
      end
    else
      @pairs_without_feedback = @student.pairs_without_feedback_today
      render :new
    end
  end

private
  def pair_feedback_params
    params.require(:pair_feedback).permit(:pair_id, :q1_response, :q2_response, :q3_response, :comments).merge(student_id: current_student.id)
  end
end
