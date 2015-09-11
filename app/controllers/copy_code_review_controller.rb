class CopyCodeReviewController < ApplicationController
  def create
    @code_review = CodeReview.find(params[:code_review][:id])
    @copy_code_review = @code_review.dup
    @copy_code_review.cohort = current_cohort
    @code_review.objectives.each do |objective|
      @objective = objective.dup
      @copy_code_review.objectives.push(@objective)
    end
    if @copy_code_review.save
      flash[:notice] = "Code review successfully copied."
      redirect_to cohort_code_reviews_path(current_cohort)
    end
  end
end
