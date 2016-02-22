class CodeReviewReportsController < ApplicationController
  def show
    @code_review = CodeReview.find(params[:code_review_id])
    @course = Course.find(params[:course_id])
    authorize! :manage, @code_review
  end
end
