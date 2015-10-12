class CodeReviewReportsController < ApplicationController
  def show
    @code_review = CodeReview.find(params[:code_review_id])
    @course = current_course
    authorize! :manage, @code_review
  end
end
