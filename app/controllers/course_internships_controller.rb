class CourseInternshipsController < ApplicationController

  def create
    course = Course.find(params[:course_internship][:course_id])
    @course_internship = CourseInternship.new(course_internship_params)
    if @course_internship.save
      redirect_to root_path, notice: "You've successfully joined #{course.description}"
    else
      @course = current_company
      render 'companies/show'
    end
  end

  def destroy
    course = Course.find(params[:course_id])
    internship = Internship.find(params[:internship_id])
    course_internship = CourseInternship.find_by(course_id: course.id, internship_id: internship.id)
    course_internship.destroy
    redirect_to internships_path, notice: "#{internship.name} has been withdrawn from the #{course.description} session."
  end

private
  def course_internship_params
    params.require(:course_internship).permit(:course_id, :internship_id)
  end
end
