class InterviewAssignmentsController < ApplicationController

  def create
    @course = Course.find(params[:course_id])
    @interview_assignment = InterviewAssignment.new(interview_assignment_params)
    if @interview_assignment.save
      redirect_to course_student_path(@course, @interview_assignment.student), notice: "Interview assignment added for #{@interview_assignment.student.name}"
    else
      @student = @interview_assignment.student
      render 'students/show'
    end
  end

  private

  def interview_assignment_params
    params.require(:interview_assignment).permit(:student_id, :internship_id)
  end
end
