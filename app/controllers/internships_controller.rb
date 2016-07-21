class InternshipsController < ApplicationController
  authorize_resource

  def index
    @courses = params[:inactive] ? Course.inactive_internship_courses : Course.active_internship_courses
    authorize! :manage, Course
  end

  def show
    @internship = Internship.find(params[:id])
    @course = Course.find(params[:course_id])
    authorize! :manage, @internship
  end

  def edit
    @internship = Internship.find(params[:id])
    authorize! :manage, @internship
  end

  def update
    @internship = Internship.find(params[:id])
    if @internship.update(internship_params)
      if current_admin
        redirect_to internships_path, notice: 'Internship has been updated'
      elsif current_company
        redirect_to root_path, notice: 'Internship has been updated'
      end
    else
      render 'edit'
    end
  end

private

  def internship_params
    params.require(:internship).permit(:name, :website, :address, :description,
                                       :ideal_intern, :clearance_required,
                                       :clearance_description, :number_of_students,
                                       track_ids: [], course_ids: [])
  end
end
