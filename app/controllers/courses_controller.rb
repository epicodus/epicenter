class CoursesController < ApplicationController
  authorize_resource

  def index
    @courses = current_student.courses.includes(:internships)
  end

  def new
    @course = Course.new(start_time: "8:00 AM", end_time: "5:00 PM")
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      current_admin.update(current_course: @course)
      redirect_to course_code_reviews_path(@course), notice: 'Class has been created!'
    else
      render :new
    end
  end

  def edit
    @course = Course.find(params[:id])
  end

  def update
    @course = Course.find(params[:id])
    if @course.update(course_params)
      redirect_to course_code_reviews_path(@course), notice: "#{@course.description} has been updated."
    else
      render :edit
    end
  end

  def destroy
    @course = Course.find(params[:id])
    @course.destroy
    redirect_to root_path, notice: "#{@course.description} has been deleted."
  end

private

  def course_params
    params[:course][:class_days] = params[:course][:class_days].split(',').map { |day| Date.parse(day) }
    params.require(:course).permit(:description, :importing_course_id, :start_time, :end_time, class_days: [])
  end
end
