class CoursesController < ApplicationController
  authorize_resource

  def index
    if params[:student_id]
      @student = Student.find_by_id(params[:student_id])
      if @student
        @courses = @student.courses
        @enrollment = Enrollment.new
        authorize! :manage, @student
      else
        redirect_to students_path(search: params[:student_id])
      end
    else
      office = Office.find_by(short_name: params[:office])
      @courses = Course.all.includes(:admin).includes(:office)
      @courses = @courses.future_courses if params[:future]
      @courses = @courses.current_courses if params[:current]
      @courses = @courses.previous_courses if params[:previous]
      @courses = current_admin.courses.includes(:office) if params[:admin_courses]
      @courses = @courses.internship_courses if params[:internships]
      @courses = @courses.courses_for(office) if office
      authorize! :manage, Course
    end
  end

  def show
    @course = Course.find(params[:id])
    @students = @course.students.order(:name).includes(:submissions)
    @enrollment = Enrollment.new
    authorize! :manage, @course
  end

  def update
    @course = Course.find(params[:id])
    if @course.update(course_params)
      flash[:notice] = "#{@course.description} has been updated."
      redirect_to internships_path(active: true)
    end
  end

private

  def course_params
    params[:course][:class_days] = params[:course][:class_days].split(',').map { |day| Date.parse(day) } if params[:course][:class_days]
    params.require(:course).permit(:admin_id, :language_id, :layout_file_path,
                                   :active, :full, :office_id, :rankings_visible, :internship_assignments_visible, class_days: [])
  end
end
