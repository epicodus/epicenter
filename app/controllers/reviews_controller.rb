class ReviewsController < ApplicationController
  authorize_resource

  def new
    @submission = Submission.find(params[:submission_id])
    @review = @submission.clone_or_build_review
  end

  def create
    @submission = Submission.find(params[:submission_id])
    @review = @submission.reviews.new(review_params)
    if @review.save
      redirect_to code_review_submissions_path(@submission.code_review), notice: 'Review saved.'
    else
      render 'new'
    end
  end

  def update
    review = Review.find(params[:id])
    if review.update_columns(note: review_params[:note])
      redirect_to new_submission_review_path(review.submission), notice: "Previous feedback updated."
    else
      redirect_to new_submission_review_path(review.submission), alert: "There was a problem updating the previous feedback."
    end
  end

private

  def review_params
    params.require(:review).permit(:student_signature, :note, grades_attributes: [:score_id, :objective_id]).merge(admin_id: current_admin.id)
  end
end
