class TranscriptsController < ApplicationController
  authorize_resource

  def show
    @completed_courses = current_student.courses.previous_courses.non_internship_courses.where.not(description: "* Placement Test").order(:start_date)
  end
end
