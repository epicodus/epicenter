class ReviewsController < ApplicationController
  def new
    @submission = Submission.find(params[:submission_id])
    @review = @submission.clone_or_build_review
  end

  def create
    @submission = Submission.find(params[:submission_id])
    @review = @submission.reviews.new(review_params)
    if @review.save
      render :create
    else
      render :errors
    end
  end

private

  def review_params
    params.require(:review).permit(:note, grades_attributes: [:score_id, :requirement_id]).merge(admin_id: current_admin.id)
  end
end
