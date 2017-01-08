class TranscriptsController < ApplicationController
  authorize_resource

  def show
    @completed_courses = current_student.courses.previous_courses.where.not(description: "* Placement Test").order(:start_date)
    unless @completed_courses.any?
      redirect_to edit_student_registration_path, alert: "Transcript not yet available."
    end
  end
end
