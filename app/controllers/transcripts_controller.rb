class TranscriptsController < ApplicationController
  authorize_resource

  def show
    if current_student
      @student = current_student
    elsif current_admin
      @student = Student.find(params[:student_id])
    end
    @completed_courses = @student.courses.previous_courses.where.not(description: "* Placement Test").order(:start_date)
    unless @completed_courses.any?
      if current_student
        redirect_to edit_student_registration_path, alert: "Transcript not yet available."
      else
        redirect_to student_courses_path(@student), alert: "Transcript not yet available."
      end
    end
  end
end
