class SubmissionsController < ApplicationController
  authorize_resource

  def index
    @code_review = CodeReview.find(params[:code_review_id])
    @submissions = @code_review.submissions.needing_review.includes(:student)
  end

  def create
    @code_review = CodeReview.find(params[:code_review_id])
    student = Student.find(submission_params[:student_id])
    @submission = @code_review.submissions.new(submission_params)
    if @submission.save
      if @code_review.submissions_not_required? && current_admin
        redirect_to new_submission_review_path(@submission)
      else
        redirect_to new_course_meeting_path(@code_review.course), notice: "Thank you for submitting."
      end
    else
      flash[:alert] = 'There was a problem submitting. Please review the form below.'
      render 'code_reviews/show'
    end
  end

  def update
    if submission_params['admin_id']
      @submission = Submission.find(params[:id])
      @submission.update_columns(admin_id: submission_params[:admin_id])
      redirect_to code_review_submissions_path(@submission.code_review)
    else
      @code_review = CodeReview.find(params[:code_review_id])
      @submission = @code_review.submission_for(current_student)
      if @submission.update(submission_params)
        redirect_to new_course_meeting_path(@code_review.course), notice: "Submission updated!"
      else
        flash[:alert] = 'There was a problem submitting. Please review the form below.'
        render 'code_reviews/show'
      end
    end
  end

private

  def submission_params
    params.require(:submission).permit(:link, :needs_review, :student_id, :times_submitted, :admin_id, notes_attributes: [:id, :content]).merge(review_status: 'pending')
  end
end
