class InternshipsController < ApplicationController
  authorize_resource

  def index
    @course = Course.find(params[:course_id])
  end

  def show
    @internship = Internship.find(params[:id])
    @course = Course.find(params[:course_id])
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
      render 'new'
    end
  end

  def edit
    @course = Course.find(params[:course_id]) if params[:course_id]
    @internship = Internship.find(params[:id])
  end

  def update
    @course = Course.find(params[:course_id]) if params[:course_id]
    @internship = Internship.find(params[:id])
    if @internship.update(internship_params)
      redirect_to company_path(@internship.company), notice: 'Your internship has been updated'
    else
      render 'edit'
    end
  end

  def destroy
    course = Course.find(params[:course_id])
    internship = Internship.find(params[:id])
    internship.destroy
    redirect_to course_internships_path(course), alert: 'Your internship has been deleted'
  end


private
  def internship_params
    params.require(:internship).permit(:name, :website, :address,
                                       :description, :ideal_intern,
                                       :clearance_required,
                                       :clearance_description, course_ids: [])
  end
end
