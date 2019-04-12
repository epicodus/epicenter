class MeetingsController < ApplicationController
  before_action { redirect_to root_path, alert: 'You are not authorized to access this page.' unless current_student }

  def new
  end

  def create
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_REVIEW'],
        :to => current_student.course.admin.email,
        :subject => "Meeting request for: #{current_student.name}",
        :text => "#{params[:meeting_explanation]}" }
    )
    redirect_to course_student_path(current_student.course, current_student), notice: "Teacher meeting request submitted."
  end
end
