class InternshipsController < ApplicationController

  include AuthenticationHelper

  before_filter :authenticate_student_and_admin

  def index
    @course = Course.find(params[:course_id])
  end

  def show
    @internship = Internship.find(params[:id])
  end

  def new
    @course = Course.find(params[:course_id])
    @internship = Internship.new
  end

  def create
    @course = Course.find(params[:course_id])
    @internship = @course.internships.new(internship_params)

    if @internship.save
      flash[:notice] = "Internship added"
      redirect_to course_internships_path(@course)
    else
      render :new
    end
  end

  def edit
    @course = Course.find(params[:course_id])
    @internship = Internship.find(params[:id])
  end

  def update
    @course = Course.find(params[:course_id])
    @internship = Internship.find(params[:id])
    if @internship.update(internship_params)
      flash[:notice] = 'Internship updated'
      redirect_to course_internships_path(@course)
    else
      render :edit
    end
  end

  def destroy
    course = Course.find(params[:course_id])
    internship = Internship.find(params[:id])
    internship.destroy
    flash[:alert] = "Internship deleted"
    redirect_to course_internships_path(course)
  end


private
  def internship_params
    params.require(:internship).permit(:company_id, :description, :ideal_intern, :clearance_required, :clearance_description)
  end
end
