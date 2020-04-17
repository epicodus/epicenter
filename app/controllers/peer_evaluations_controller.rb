class PeerEvaluationsController < ApplicationController
  authorize_resource

  def index
    if params[:student_id]
      @student = Student.find(params[:student_id])
      authorize! :read, @student
    elsif params[:course_id]
      @course = Course.find(params[:course_id])
      authorize! :manage, @course
    end
  end

  def new
    @student = current_student
    @peer_evaluation = PeerEvaluation.new
    PeerQuestion.all.each { |q| @peer_evaluation.peer_responses.build(peer_question: q) }
    @options = PeerResponse::OPTIONS
    authorize! :read, @student
  end

  def create
    peer_evaluation = PeerEvaluation.new(peer_evaluation_params)
    if peer_evaluation.save
      redirect_to new_student_peer_evaluation_path(peer_evaluation.evaluator), notice: "Peer evaluation of #{peer_evaluation.evaluatee.name} submitted."
    else
      @student = current_student
      @peer_evaluation = peer_evaluation
      render :new
    end
  end

  def show
    @student = Student.find(params[:student_id])
    @peer_evaluation = PeerEvaluation.find(params[:id])
    @options = PeerResponse::OPTIONS
    authorize! :read, @student
    authorize! :read, @peer_evaluation
  end

private
  def peer_evaluation_params
    params.require(:peer_evaluation).permit(:evaluatee_id, peer_responses_attributes: [:peer_question_id, :response]).merge(evaluator_id: current_student.id)
  end
end
