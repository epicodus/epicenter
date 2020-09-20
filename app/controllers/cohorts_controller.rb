class CohortsController < ApplicationController
  authorize_resource

  def index
    @cohorts = Cohort.all.includes(:admin).includes(:office).includes(:track)
  end

  def show
    @cohort = Cohort.find(params[:id])
    @courses = @cohort.courses.includes(:admin).includes(:office)
  end

  def new
    @cohort = Cohort.new
  end

  def create
    @cohort = Cohort.new(cohort_params)
    if @cohort.save
      redirect_to cohort_path(@cohort), notice: 'Cohort has been created.'
    else
      render :new
    end
  end

  def edit
    @cohort = Cohort.find(params[:id])
  end

  def update
    @cohort = Cohort.find(params[:id])
    if @cohort.update(cohort_params)
      flash[:notice] = "#{@cohort.description} has been updated."
      redirect_to cohort_path(@cohort)
    else
      render :edit
    end
  end

private

  def cohort_params
    params.require(:cohort).permit(:start_date, :office_id, :admin_id, :track_id, :description, :layout_file_path)
  end
end
