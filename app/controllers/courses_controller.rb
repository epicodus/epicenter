class CoursesController < ApplicationController
  authorize_resource

  def index
    if params[:student_id]
      @student = Student.find(params[:student_id])
      @courses = @student.courses
      authorize! :manage, @student
    else
      @courses = Course.all.includes(:admin).includes(:office)
      authorize! :manage, Course
    end
  end

  def show
    @course = Course.find(params[:id])
    @students = @course.students.order(:name).includes(:submissions).page(params[:page]).per(15)
    @students = @students.per(@course.students.count) if params[:all]
    @enrollment = Enrollment.new
    authorize! :manage, @course
  end

  def new
    @course = Course.new(start_time: "8:00 AM", end_time: "5:00 PM")
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      current_admin.update(current_course: @course)
      redirect_to course_path(@course), notice: 'Course has been created.'
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
      flash[:notice] = "#{@course.description} has been updated."
      if request.referer.include?('internships')
        redirect_to internships_path(active: true)
      else
        redirect_to course_path(@course)
      end
    else
      render :edit
    end
  end

private

  def course_params
    params[:course][:class_days] = params[:course][:class_days].split(',').map { |day| Date.parse(day) } if params[:course][:class_days]
    params.require(:course).permit(:admin_id, :description, :importing_course_id,
                                   :start_time, :end_time, :internship_course,
                                   :active, :office_id, :rankings_visible, class_days: [])
  end
end
