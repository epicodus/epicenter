class StudentsController < ApplicationController
  authorize_resource

  def index
    authorize! :manage, Course
    if params[:search]
      @query = params[:search]
      @results = Student.with_deleted.includes(:courses).search(@query).order(:name)
      render 'search_results'
    else
      redirect_to root_path
    end
  end

  def show
    @student = Student.find(params[:id])
    @course = Course.find(params[:course_id]) if params[:course_id]
    @interview_assignment = InterviewAssignment.new
    @internship_assignment = InternshipAssignment.new
    authorize! :read, @course
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

  def destroy
    @student = Student.find(params[:id])
    @student.destroy
    redirect_to root_path, notice: "#{@student.name} has been archived!"
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id, :course_id, :plan_id,
                                    ratings_attributes: [:id, :internship_id, :number])
  end

  def update_student_as_admin
    @student = Student.find(params[:id])
    if @student.update(student_params)
      if student_params[:plan_id]
        redirect_to student_payments_path(@student), notice: "Payment plan for #{@student.name} has been updated."
      else
        redirect_to student_courses_path(@student), notice: "Courses for #{@student.name} have been updated."
      end
    else
      if student_params[:plan_id]
        redirect_to student_payments_path(@student), alert: "Payment plan update failed."
      else
        @course = Course.find(params[:student][:course_id])
        render 'show'
      end
    end
  end

  def redirect_appropriately
    if request.referer.include?('payment_methods')
      redirect_to payment_methods_path, notice: 'Primary payment method has been updated.'
    else
      @course = Course.find(Rails.application.routes.recognize_path(request.referrer)[:course_id])
      redirect_to course_student_path(@course, current_student), notice: 'Internship rankings have been updated.'
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
