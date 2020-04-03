class DailySubmissionsController < ApplicationController
  authorize_resource

  def index
    @student = Student.find(params[:student_id])
    authorize! :read, @student
  end

  def show
    @course = Course.find(params[:course_id])
    @date = params[:date] ? Date.parse(params[:date]) : Time.zone.now.to_date
    authorize! :manage, @course
  end

  def create
    student = Student.find(params[:student_id])
    @daily_submission = student.daily_submissions.new(daily_submission_params)
    if @daily_submission.save
      redirect_to course_student_path(student.course, student), notice: 'Thank you for your daily submission.'
    else
      redirect_to course_student_path(student.course, student), alert: 'There was a problem submitting. Please review the daily submission form.'
    end
  end

private

  def daily_submission_params
    params.require(:daily_submission).permit(:link, :date)
  end
end
