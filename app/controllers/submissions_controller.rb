class SubmissionsController < ApplicationController
  authorize_resource

  def index
    @code_review = CodeReview.find(params[:code_review_id])
    @submissions = @code_review.submissions.needing_review.includes(:student)
  end

  def create
    @code_review = CodeReview.find(params[:code_review_id])
    binding.pry
    @code_review.surveys.create(survey_params.merge(student: current_student)) if params[:survey]
    @submission = @code_review.submissions.new(submission_params)
    if @submission.save
      if @code_review.submissions_not_required? && current_admin
        redirect_to new_submission_review_path(@submission)
      else
        redirect_to course_code_review_path(@code_review.course, @code_review), notice: "Thank you for submitting."
      end
    else
      flash[:alert] = 'There was a problem submitting. Please review the form below.'
      render 'code_reviews/show'
    end
  end

  def update
    if submission_params['times_submitted']
      @submission = Submission.find(params[:id])
      @submission.update_columns(times_submitted: submission_params[:times_submitted])
      render 'update_submission_times'
    else
      @code_review = CodeReview.find(params[:code_review_id])
      @submission = @code_review.submission_for(current_student)
      if @submission.update(submission_params)
        redirect_to course_code_review_path(@code_review.course, @code_review), notice: "Submission updated!"
      else
        flash[:alert] = 'There was a problem submitting. Please review the form below.'
        render 'code_reviews/show'
      end
    end
  end

private

  def submission_params
    params.require(:submission).permit(:link, :needs_review, :student_id, :times_submitted, notes_attributes: [:id, :content]).merge(review_status: 'pending')
  end

  def survey_params
    params.require(:survey).permit(:teacher_help, :teacher_help_note, :teacher_availability, :teacher_availability_note, :curriculum_clarity, :curriculum_clarity_note, :project_prep, :project_prep_note, :project_prompt, :project_prompt_note)
  end
end
