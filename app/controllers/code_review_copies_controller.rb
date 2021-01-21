class CodeReviewCopiesController < ApplicationController
  def create
    code_review = CodeReview.find(code_review_params[:id])
    course = Course.find(code_review_params[:course_id])
    copy_code_review = code_review.duplicate_code_review(course)
    if copy_code_review.save
      flash[:notice] = "Code review successfully copied."
      redirect_to course_path(course)
    end
  end

private
  def code_review_params
    params.require(:code_review).permit(:id, :course_id)
  end
end
