class CodeReviewReportsController < ApplicationController
  def show
    @code_review = CodeReview.find(params[:code_review_id])
    @cohort = current_cohort
    authorize! :manage, @code_review
  end
end
