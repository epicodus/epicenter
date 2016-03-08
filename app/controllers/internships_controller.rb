class InternshipsController < ApplicationController
  authorize_resource

  def index
    @course = Course.find(params[:course_id])
  end

  def show
    @internship = Internship.find(params[:id])
    @course = Course.find(params[:course_id])
  end

  def edit
    @internship = Internship.find(params[:id])
    authorize! :manage, @internship
  end

  def update
    @internship = Internship.find(params[:id])
    if @internship.update(internship_params)
      redirect_to root_path, notice: 'Internship has been updated'
    else
      render 'edit'
    end
  end

  def destroy
    internship = Internship.find(params[:id])
    internship.destroy
    redirect_to root_path, alert: 'Internship has been deleted'
  end

private

  def internship_params
    params.require(:internship).permit(:name, :website, :address, :description, :ideal_intern,
                                       :clearance_required, :clearance_description, course_ids: [])
  end
end
