class StudentsController < ApplicationController
  authorize_resource

  def index
    @students = current_admin.current_course.students
    @enrollment = Enrollment.new
  end

  def show
    @student = Student.find(params[:id])
    authorize! :read, @student
  end

  def update
    if current_admin
      student = Student.find(params[:id])
      if student.update(student_params)
        redirect_to :back, notice: "Courses for #{student.name} have been updated"
      else
        redirect_to :back, alert: "There was an error."
      end
    elsif current_student
      if current_student.update(student_params)
        if request.referer.include?('internships')
          redirect_to :back, notice: "Ratings have been updated."
        else
          redirect_to :back, notice: "Primary payment method has been updated."
        end
      else
        if request.referer.include?('internships')
          @course = Course.find(Rails.application.routes.recognize_path(request.referrer)[:course_id])
          render 'internships/index'
        else
          @payments = current_student.payments
          render 'payments/index'
        end
      end
    end
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id,
                                    :course_id,
                                    ratings_attributes: [:id, :interest, :internship_id, :notes])
  end
end
