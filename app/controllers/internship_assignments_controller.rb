class InternshipAssignmentsController < ApplicationController

  def create
    @course = Course.find(params[:internship_assignment][:course_id])
    @student = Student.find(params[:internship_assignment][:student_id])
    internship = Internship.find(params[:internship_assignment][:internship_id])
    @internship_assignment = InternshipAssignment.new(internship_assignment_params)
    if @internship_assignment.save
      redirect_to course_student_path(@course, @student), notice: "#{@student.name} has been assigned to #{internship.name}"
    else
      render 'students/show'
    end
  end

  def destroy
    internship_assignment = InternshipAssignment.find(params[:id])
    internship_assignment.destroy
    redirect_to course_student_path(internship_assignment.course, internship_assignment.student), notice: "#{internship_assignment.internship.name} has been unassigned from #{internship_assignment.student.name}"
  end

  private

  def internship_assignment_params
    params.require(:internship_assignment).permit(:student_id, :internship_id, :course_id)
  end
end
