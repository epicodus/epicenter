class PairFeedbacksController < ApplicationController
  authorize_resource

  def index
    @student = Student.find(params[:student_id])
    authorize! :manage, Course
  end

  def new
    @student = current_student
    @pair_feedback = PairFeedback.new
    authorize! :read, @student
  end

  def create
    @pair_feedback = PairFeedback.new(pair_feedback_params)
    @student = current_student
    if @pair_feedback.save
      redirect_to course_student_path(@student.course, @student), notice: "Pair feedback submitted."
    else
      render :new
    end
  end

private
  def pair_feedback_params
    params.require(:pair_feedback).permit(:pair_id, :q1_response, :q2_response, :q3_response, :comments).merge(student_id: current_student.id)
  end
end
