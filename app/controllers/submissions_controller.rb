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
      if @code_review.submissions_not_required? && current_admin
        redirect_to new_submission_review_path(@submission)
      else
        redirect_to course_code_review_path(@code_review.course, @code_review), notice: "Thank you for submitting."
      end
    else
      render 'code_reviews/show'
    end
  end

  def update
    if params['times_submitted']
      @submission = Submission.find(params[:id])
      times_submitted = @submission.times_submitted + 1 if params['times_submitted'] == "increment"
      times_submitted = @submission.times_submitted - 1 if params['times_submitted'] == "decrement"
      @submission.update_columns(times_submitted: times_submitted)
      render 'update_submission_times'
    else
      @code_review = CodeReview.find(params[:code_review_id])
      @submission = @code_review.submission_for(current_student)
      if @submission.update(submission_params)
        redirect_to course_code_review_path(@code_review.course, @code_review), notice: "Submission updated!"
      else
        render 'code_reviews/show'
      end
    end
  end

private

  def submission_params
    params.require(:submission).permit(:link, :needs_review, :student_id)
  end
end
