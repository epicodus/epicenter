class EnrollmentsController < ApplicationController

  def create
    @cohort = Cohort.find_by_id(params[:enrollment][:cohort_id])
    @course = Course.find_by_id(params[:enrollment][:course_id])
    @student = Student.find(params[:enrollment][:student_id])
    @previous_current_cohort = @student.cohort
    if @cohort
      @cohort.courses.current_and_future_courses.each do |course|
        Enrollment.create(student: @student, course: course)
      end
      @confirmation_message = "#{@student.name} enrolled in all current and future courses in #{@cohort.description}."
    elsif @course
      @enrollment = Enrollment.new(student: @student, course: @course)
      if @enrollment.save
        @confirmation_message = "#{@student.name} enrolled in #{@course.description_and_office}."
      else
        render 'courses/index'
      end
    end
    @possible_cohorts = @student.courses.cirr_fulltime_courses.map {|c| c.cohorts}.flatten.uniq
    respond_to do |format|
      format.js {
        if @possible_cohorts.count > 1 && (Course.cirr_fulltime_courses.include?(@course) || Course.cirr_fulltime_courses.include?(@cohort.try(:courses).try(:first)))
          render 'cohorts/cohort_select_modal'
        else
          cohort_confirmation_message = @student.reload.cohort == @previous_current_cohort ? "Current cohort has not been changed." : "Current cohort has been set to #{@student.cohort.try(:description) || 'blank'}."
          flash[:notice] = @confirmation_message + "<br>" + cohort_confirmation_message
          render js: "window.location.pathname ='#{student_courses_path(@student)}'"
        end
      }
    end
  end

  def destroy
    if params['really_destroy'] == 'true'
      enrollment = Enrollment.only_deleted.find(params[:id])
      enrollment.really_destroy!
      redirect_to student_courses_path(enrollment.student), notice: "Enrollment permanently removed: #{enrollment.course.description}"
    else
      @student = Student.find(params[:id])
      @previous_current_cohort = @student.cohort
      course = Course.find(params[:course_id])
      enrollment = Enrollment.find_by(course_id: course.id, student_id: @student.id)
      enrollment.destroy
      @confirmation_message = "#{@student.name} has been withdrawn from #{course.description_and_office}."
      @possible_cohorts = @student.courses.cirr_fulltime_courses.map {|c| c.cohorts}.flatten.uniq
      respond_to do |format|
        format.js {
          if Course.cirr_fulltime_courses.include?(course) && @possible_cohorts.count > 1
            render 'cohorts/cohort_select_modal'
          else
            cohort_confirmation_message = @student.reload.cohort == @previous_current_cohort ? "Current cohort has not been changed." : "Current cohort has been set to #{@student.cohort.try(:description) || 'blank'}."
            flash[:notice] = @confirmation_message + "<br>" + cohort_confirmation_message
            render js: "window.location.pathname ='#{student_courses_path(@student)}'"
          end
        }
      end
    end
  end

private
  def enrollment_params
    params.require(:enrollment).permit(:student_id, :course_id, :cohort_id)
  end
end
