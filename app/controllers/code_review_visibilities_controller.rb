class CodeReviewVisibilitiesController < ApplicationController
  before_action :authenticate_admin!

  def update
    code_review = CodeReview.find(params[:code_review_id])
    student = Student.find(params[:student_id])
    code_review_visibility = code_review.code_review_visibility_for(student)
    if code_review_visibility.update(code_review_visibility_params)
      if code_review_visibility.special_permission
        redirect_to course_student_path(code_review.course, student), notice: "#{code_review.title} made visible for #{student.name}"
      else
        redirect_to course_student_path(code_review.course, student), alert: "#{code_review.title} visibility marker removed for #{student.name}"
      end
    else
      redirect_to new_code_review_submission_path(code_review, student_id: student.id), alert: "There was a problem updating the visibility marker."
    end
  end

  private

  def code_review_visibility_params
    params.require(:code_review_visibility).permit(:special_permission)
  end
end
