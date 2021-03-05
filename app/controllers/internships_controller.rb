class InternshipsController < ApplicationController
  authorize_resource

  def index
    office = Office.find_by(short_name: params[:office])
    @courses = Course.internship_courses
    @courses = @courses.active_internship_courses if params[:active]
    @courses = @courses.inactive_internship_courses if params[:inactive]
    @courses = @courses.courses_for(office) if office
    authorize! :manage, Course
  end

  def show
    @internship = Internship.find(params[:id])
    @course = Course.find(params[:course_id])
    authorize! :read, @course
    authorize! :read, @internship
  end

  def edit
    @internship = Internship.find(params[:id])
    authorize! :manage, @internship
  end

  def update
    @internship = Internship.find(params[:id])
    if @internship.update(internship_params)
      if current_admin
        redirect_to internships_path(active: true), notice: 'Internship has been updated'
      elsif current_company
        redirect_to root_path, notice: 'Internship has been updated'
      end
    else
      render 'edit'
    end
  end

private

  def internship_params
    params.require(:internship).permit(:name, :website, :address, :interview_location, :description,
                                       :ideal_intern, :clearance_required,
                                       :clearance_description, :number_of_students, :remote, :hiring,
                                       track_ids: [], course_ids: [])
  end
end
