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

  def destroy
    course = Course.find(params[:course_id])
    student = Student.find(params[:student_id])
    internship = Internship.find(params[:internship_id])
    interview_assignment = InterviewAssignment.find_by(internship_id: internship.id, student_id: student.id)
    interview_assignment.destroy
    redirect_to course_student_path(course, student), notice: "Interview assignment removed for #{student.name}"
  end

  private

  def interview_assignment_params
    params.require(:interview_assignment).permit(:student_id, :internship_id)
  end
end
