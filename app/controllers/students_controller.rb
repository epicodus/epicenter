class StudentsController < ApplicationController
  authorize_resource

  def index
    authorize! :manage, Course
    if params[:search]
      if params[:search].match?(/^[0-9]*$/)
        @query = Student.with_deleted.find_by_id(params[:search]).try(:email)
      else
        @query = params[:search]
      end
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

  def edit
    # show cohort select modal
    authorize! :manage, Course
    @student = Student.find(params[:id])
    if params[:starting] == 'true'
      respond_to do |format|
        format.js { render 'cohorts/starting_cohort_select_modal' }
      end
    else
      @confirmation_message = 'Edit current cohort'
      @previous_current_cohort = @student.cohort
      @possible_cohorts = Cohort.where(id: @student.courses.cirr_fulltime_courses.pluck(:cohort_id))
      respond_to do |format|
        format.js { render 'cohorts/cohort_select_modal' }
      end
    end
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
    student = Student.find(params[:id])
    if params['drop_all'] == 'true'
      student.enrollments.destroy_all
      redirect_to student_courses_path(student), notice: "#{student.email} has been withdrawn from all courses."
    else
      student = Student.find(params[:id])
      student.destroy
      redirect_to root_path, notice: "#{student.name} has been archived! (#{view_context.link_to('view', students_path(search: student.id)).html_safe})"
    end
  end

private
  def student_params
    params[:student][:upfront_amount] = params[:student][:upfront_amount].to_i * 100 if params[:student][:upfront_amount]
    params.require(:student).permit(:primary_payment_method_id, :course_id, :cohort_id, :starting_cohort_id, :plan_id, :probation_teacher,
                                    :probation_advisor, :upfront_amount, :staff_sticky, ratings_attributes: [:id, :internship_id, :number])
  end

  def update_student_as_admin
    @student = Student.find(params[:id])
    if @student.update(student_params)
      if student_params[:cohort_id]
        redirect_to student_courses_path(@student), notice: "Current cohort for #{@student.name} has been set to #{@student.cohort.try(:description) || 'blank'}."
      elsif student_params[:starting_cohort_id]
        redirect_to student_courses_path(@student), notice: "Starting cohort for #{@student.name} has been set to #{@student.starting_cohort.try(:description) || 'blank'}."
      elsif student_params[:plan_id]
        redirect_to student_payments_path(@student), notice: "Payment plan for #{@student.name} has been updated. Upfront amount total has been reset."
      elsif student_params[:upfront_amount]
        redirect_to student_payments_path(@student), notice: "Upfront tuition total for #{@student.name} has been updated to $#{@student.upfront_amount / 100}. Remaining upfront amount owed is $#{@student.upfront_amount_owed / 100}."
      end
      if student_params[:probation_teacher]
        if @student.probation_teacher
          @student.probation_teacher_count = (@student.probation_teacher_count || 0) + 1
          @student.save
          redirect_back(fallback_location: student_courses_path(@student), alert: "#{@student.name} has been placed on teacher warning!")
        else
          redirect_back(fallback_location: student_courses_path(@student), notice: "#{@student.name} has been removed from teacher warning! :)")
        end
      elsif student_params[:probation_advisor]
        if @student.probation_advisor
          @student.probation_advisor_count = (@student.probation_advisor_count || 0) + 1
          @student.save
          redirect_back(fallback_location: student_courses_path(@student), alert: "#{@student.name} has been placed on advisor warning!")
        else
          redirect_back(fallback_location: student_courses_path(@student), notice: "#{@student.name} has been removed from advisor warning! :)")
        end
      end
    else
      if student_params[:cohort_id]
        redirect_back(fallback_location: student_courses_path(@student), alert: "Cohort update failed.")
      elsif student_params[:starting_cohort_id]
        redirect_back(fallback_location: student_courses_path(@student), alert: "Starting cohort update failed.")
      elsif student_params[:plan_id]
        redirect_to student_payments_path(@student), alert: "Payment plan update failed."
      elsif student_params[:upfront_amount]
        redirect_to student_payments_path(@student), alert: "Upfront tuition update failed."
      end
      if student_params[:probation_teacher] || student_params[:probation_advisor]
        redirect_back(fallback_location: student_courses_path(@student), alert: "Academic Warning status update failed.")
      end
    end
  end

  def redirect_appropriately
    if student_params[:plan_id]
      if current_student.plan.try(:short_name) == 'isa'
        redirect_to student_payments_path(current_student), notice: "You've selected the ISA payment plan. Please pay your deposit to our ISA Partner Mia Share. Click <a href='https://epicodus.mia-share.com/' target='_blank'>here</a> to apply and pay with Mia Share."
      else
        redirect_to student_payments_path(current_student), notice: 'Payment plan selected. Please make payment below.'
      end
    elsif request.referer.include?('payment_methods')
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
