class ProbationsController < ApplicationController
  before_action { redirect_to root_path, alert: 'You are not authorized to access this page.' unless current_admin }

  def edit
    @student = Student.find(params[:student_id])
  end

  def update
    @student = Student.find(params[:student_id])
    @student.probation_teacher_count = params[:probation_teacher_count]
    @student.probation_advisor_count = params[:probation_advisor_count]
    if @student.save
      redirect_to student_courses_path(@student), notice: 'Academic Warning counts updated'
    else
      render :edit
    end
  end
end
