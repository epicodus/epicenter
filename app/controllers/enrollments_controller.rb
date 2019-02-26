class EnrollmentsController < ApplicationController

  def create
    @cohort = Cohort.find_by_id(params[:enrollment][:cohort_id])
    @course = Course.find_by_id(params[:enrollment][:course_id])
    @student = Student.find(params[:enrollment][:student_id])
    if @cohort
      @cohort.courses.current_and_future_courses.each do |course|
        Enrollment.create(student: @student, course: course)
      end
      redirect_to student_courses_path(@student), notice: "#{@student.name} enrolled in all current and future courses in #{@cohort.description}."
    elsif @course
      @enrollment = Enrollment.new(student: @student, course: @course)
      if @enrollment.save
        redirect_to student_courses_path(@student), notice: "#{@student.name} enrolled in #{@course.description}."
      else
        render 'courses/index'
      end
    end
  end

  def destroy
    if params['really_destroy'] == 'true'
      enrollment = Enrollment.only_deleted.find(params[:id])
      enrollment.really_destroy!
      redirect_to student_courses_path(enrollment.student), notice: "Enrollment permanently removed: #{enrollment.course.description}"
    else
      student = Student.find(params[:id])
      course = Course.find(params[:course_id])
      enrollment = Enrollment.find_by(course_id: course.id, student_id: student.id)
      enrollment.destroy
      redirect_to student_courses_path(student), notice: "#{course.description} has been removed"
    end
  end

private
  def enrollment_params
    params.require(:enrollment).permit(:student_id, :course_id, :cohort_id)
  end
end
