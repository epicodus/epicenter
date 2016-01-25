class EnrollmentsController < ApplicationController

  def create
    @course = Course.find(params[:enrollment][:course_id])
    @student = Student.find(params[:enrollment][:student_id])
    @enrollment = Enrollment.new(enrollment_params)
    if @enrollment.save
      redirect_to course_students_path(@course), notice: "#{@student.name} has been added to this course"
    else
      render 'students/index'
    end
  end

  def destroy
    student = Student.find(params[:id])
    course = Course.find(params[:course_id])
    enrollment = Enrollment.find_by(course_id: course.id, student_id: student.id)
    enrollment.destroy
    redirect_to course_student_path(course, student), notice: "#{course.description} has been removed"
  end

private
  def enrollment_params
    params.require(:enrollment).permit(:student_id, :course_id)
  end
end
