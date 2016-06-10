class InterviewAssignmentsController < ApplicationController

  def create_multiple
    @course = Course.find(params[:course_id])
    @student = Student.find(params[:student_id])
    interview_assignments = interview_assignment_params[:internship_id].map do |internship_id|
      InterviewAssignment.new(student_id: @student.id, internship_id: internship_id)
    end
    if interview_assignments.each { |interview_assignment| interview_assignment.save }
      redirect_to course_student_path(@course, @student), notice: "Interview assignments added for #{@student.name}."
    else
      render 'students/show'
    end
  end

  def destroy
    course = Course.find(params[:course_id])
    student = Student.find(params[:student_id])
    internship = Internship.find(params[:internship_id])
    interview_assignment = InterviewAssignment.find_by(internship_id: internship.id, student_id: student.id)
    interview_assignment.destroy
    redirect_to course_student_path(course, student), notice: "Interview assignment removed for #{student.name}."
  end

  private

  def interview_assignment_params
    params.require(:interview_assignment).permit(:student_id, internship_id: [])
  end
end
