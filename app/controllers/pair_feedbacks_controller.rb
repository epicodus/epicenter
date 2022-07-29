class PairFeedbacksController < ApplicationController
  authorize_resource

  def index
    @student = Student.find(params[:student_id])
    authorize! :manage, Course
  end

  def new
    @student = current_student
    authorize! :read, @student
    if @student.signed_in_today? && @student.pairs_without_feedback_today.any?
      @pairs_without_feedback = @student.pairs_without_feedback_today
      @pair_feedback = PairFeedback.new
    elsif @student.signed_in_today? && @student.pairs_today.any?
      redirect_to root_path, notice: "All pair feedback submitted for today. :)"
    elsif @student.signed_in_today?
      redirect_to root_path, alert: "You signed in solo today."
    else
      redirect_to root_path, alert: "You haven't signed in yet today."
    end
  end

  def create
    @student = current_student
    @pair_feedback = PairFeedback.new(pair_feedback_params)
    if @pair_feedback.save
      redirect_to pair_feedback_path
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
