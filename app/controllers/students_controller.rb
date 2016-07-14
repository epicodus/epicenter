class StudentsController < ApplicationController
  authorize_resource

  def index
    authorize! :manage, Course
    if params[:search]
      @query = params[:search]
      @results = Student.includes(:courses).search(@query)
      render 'search_results'
    elsif params[:course_id]
      @course = Course.find(params[:course_id])
      @students = @course.students.includes(:submissions)
      @enrollment = Enrollment.new
    else
      redirect_to root_path
    end
  end

  def show
    @student = Student.find(params[:id])
    @course = Course.find(params[:course_id]) if params[:course_id]
    @interview_assignment = InterviewAssignment.new
    authorize! :read, @student
  end

  def update
    if current_admin
      update_student_as_admin
    elsif current_student
      if current_student.update(student_params)
        redirect_appropriately
      else
        render_errors_appropriately
      end
    end
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id, :course_id, :interview_feedback,
                                    ratings_attributes: [:id, :interest, :internship_id, :notes])
  end

  def update_student_as_admin
    @student = Student.find(params[:id])
    if @student.update(student_params)
      if params[:student][:interview_feedback]
        redirect_to course_student_path(Course.find(params[:course_id]), @student), notice: "Interview feedback added for #{@student.name}."
      else
        redirect_to student_courses_path(@student), notice: "Courses for #{@student.name} have been updated."
      end
    else
      @course = Course.find(params[:student][:course_id])
      render 'show'
    end
  end

  def redirect_appropriately
    if request.referer.include?('payment_methods')
      redirect_to payment_methods_path, notice: 'Primary payment method has been updated.'
    else
      @course = Course.find(Rails.application.routes.recognize_path(request.referrer)[:course_id])
      redirect_to course_student_path(@course, current_student), notice: 'Internship ratings have been updated.'
    end
  end

  def render_errors_appropriately
    if request.referer.include?('payment_methods')
      @payments = current_student.payments
      render 'payments/index'
    else
      @student = Student.find(params[:id])
      @course = Course.find(Rails.application.routes.recognize_path(request.referrer)[:course_id])
      render 'students/show'
    end
  end
end
