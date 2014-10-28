class ReviewsController < ApplicationController
  def new
    @submission = Submission.find(params[:submission_id])
    @review = Review.new(submission: @submission)
    @submission.assessment.requirements.each do |requirement|
      @review.grades.build(requirement: requirement)
    end
  end

  def create
    @submission = Submission.find(params[:submission_id])
    @review = @submission.reviews.create(review_params)
  end

  private

  def review_params
    params.require(:review).permit(:note, grades_attributes: [:score]).merge(user_id: current_user.id)
  end
end
