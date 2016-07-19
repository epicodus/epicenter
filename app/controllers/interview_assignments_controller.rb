class InterviewAssignmentsController < ApplicationController

  def create_multiple
    @course = Course.find(params[:course_id])
    @student = Student.find(params[:student_id])
    interview_assignments = interview_assignment_params[:internship_id].map do |internship_id|
      InterviewAssignment.create(student_id: @student.id, internship_id: internship_id, course_id: @course.id)
    end
    if interview_assignments_created_successfully(interview_assignments)
      redirect_to course_student_path(@course, @student), notice: "Interview assignments added for #{@student.name}."
    else
      flash.now[:alert] = "Something went wrong: " + interview_assignments.first.errors.full_messages.join(", ")
      render 'students/show'
    end
  end

  def update_multiple
    course = Course.find(params[:course_id])
    InterviewAssignment.update(params[:interview_assignments].keys, params[:interview_assignments].values)
    redirect_to current_company, notice: "Student rankings have been saved for #{course.description}."
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

  def interview_assignments_created_successfully(interview_assignments)
    !interview_assignments.map(&:persisted?).include?(false)
  end

  def interview_assignment_params
    params[:interview_assignment][:internship_id] = params.dig(:interview_assignment).dig(:internship_id).select!(&:present?)
    params.require(:interview_assignment).permit(:student_id, internship_id: [])
  end
end
