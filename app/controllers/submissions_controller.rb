class SubmissionsController < ApplicationController
  authorize_resource

  def index
    @code_review = CodeReview.find(params[:code_review_id])
    @submissions = @code_review.submissions.needing_review.includes(:student)
  end

  def new
    @code_review = CodeReview.find(params[:code_review_id])
    @student = Student.find(params[:student_id])
    @code_review_visibility = @code_review.code_review_visibility_for(@student)
  end

  def create
    @code_review = CodeReview.find(params[:code_review_id])
    student = Student.find(submission_params[:student_id])
    @submission = @code_review.submission_for(student) || @code_review.submissions.new(submission_params)
    if @submission.save
      if current_admin && @submission.exempt?
        redirect_to course_student_path(@code_review.course, student), notice: "#{@code_review.title} marked as passing for #{student.name}"
      elsif current_admin && @code_review.submissions_not_required?
        redirect_to new_submission_review_path(@submission)
      elsif @code_review.journal?
        @submission.reviews.create(note: "reflection submitted", student_signature: "n/a", admin_id: Admin.reorder(:id).first.id)
        redirect_to course_student_path(@code_review.course, student), notice: "Thank you for submitting your reflection."
      else
        redirect_to new_course_meeting_path(@code_review.course), notice: "Thank you for submitting."
      end
    else
      flash[:alert] = 'There was a problem submitting. Please review the form below.'
      render 'code_reviews/show'
    end
  end

  def update
    if params[:source_course_id]
      move_submissions
    elsif submission_params['times_submitted']
      @submission = Submission.find(params[:id])
      @submission.update_columns(times_submitted: submission_params[:times_submitted])
      render 'update_submission_times'
    elsif submission_params['admin_id']
      @submission = Submission.find(params[:id])
      @submission.update_columns(admin_id: submission_params[:admin_id])
      redirect_to code_review_submissions_path(@submission.code_review)
    elsif submission_params['meeting_fulfilled']
      @submission = Submission.find(params[:id])
      @submission.meeting_request_notes.destroy_all
      render 'meeting_fulfilled'
    else
      @code_review = CodeReview.find(params[:code_review_id])
      @submission = @code_review.submission_for(current_student)
      if @submission.update(submission_params)
        if @code_review.journal?
          @submission.reviews.create(note: "reflection submitted", student_signature: "n/a", admin_id: Admin.reorder(:id).first.id)
          redirect_to course_student_path(@code_review.course, current_student), notice: "Reflection updated!"
        else
          redirect_to new_course_meeting_path(@code_review.course), notice: "Submission updated!"
        end
      else
        flash[:alert] = 'There was a problem submitting. Please review the form below.'
        render 'code_reviews/show'
      end
    end
  end

private

  def submission_params
    params.require(:submission).permit(:link, :journal, :needs_review, :student_id, :times_submitted, :admin_id, :meeting_fulfilled, :exempt, submission_notes_attributes: [:id, :content]).merge(review_status: 'pending')
  end

  def move_submissions
    student = Student.find(params[:student_id])
    source_course = Course.find(params[:source_course_id])
    destination_course = Course.find(params[:destination_course_id])
    Course.move_submissions(student: student, source_course: source_course, destination_course: destination_course)
    redirect_to course_student_path(destination_course, student), notice: "Eligible submissions for #{student.name} moved to this course."
  end
end
