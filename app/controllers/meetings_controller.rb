class MeetingsController < ApplicationController
  before_action { redirect_to root_path, alert: 'You are not authorized to access this page.' unless current_student }

  def new
    @course = Course.find(params[:course_id])
  end

  def create
    course = Course.find(params[:course_id])
    submission = current_student.submissions.last
    meeting_request_note = submission.meeting_request_notes.create(content: params[:meeting_explanation])
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_REVIEW'],
        :to => course.admin.email,
        :subject => "Meeting request for: #{current_student.name}",
        :text => meeting_request_note.content }
    )
    redirect_to course_student_path(course, current_student), notice: "Teacher meeting request submitted."
  end
end
