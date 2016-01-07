class SubmissionsController < ApplicationController
  authorize_resource

  def index
    @code_review = CodeReview.find(params[:code_review_id])
    @submissions = @code_review.submissions.needing_review.includes(:student)
  end

  def create
    @code_review = CodeReview.find(params[:code_review_id])
    @submission = @code_review.submissions.new(submission_params)
    if @submission.save
      redirect_to @code_review, notice: "Thank you for submitting."
    else
      render 'code_reviews/show'
    end
  end

  def update
    @code_review = CodeReview.find(params[:code_review_id])
    @submission = @code_review.submission_for(current_student)
    if @submission.update(submission_params)
      redirect_to @code_review, notice: "Submission updated!"
    else
      render 'code_reviews/show'
    end
  end

private

  def submission_params
    params.require(:submission).permit(:link, :needs_review).merge(student_id: current_student.id)
  end
end
