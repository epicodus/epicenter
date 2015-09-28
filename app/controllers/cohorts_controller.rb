class CohortsController < ApplicationController
  authorize_resource

  def new
    @cohort = Cohort.new
  end

  def create
    @cohort = Cohort.new(cohort_params)
    @cohort.start_date = @cohort.class_days.split(",").first
    @cohort.end_date = @cohort.class_days.split(",").last
    if @cohort.save
      current_admin.update(current_cohort: @cohort)
      redirect_to cohort_code_reviews_path(@cohort), notice: 'Class has been created!'
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
      redirect_to cohort_code_reviews_path(@cohort), notice: "#{@cohort.description} has been updated."
    else
      render :edit
    end
  end

  def destroy
    @cohort = Cohort.find(params[:id])
    @cohort.destroy
    redirect_to root_path, notice: "#{@cohort.description} has been deleted."
  end

private

  def cohort_params
    params.require(:cohort).permit(:description, :start_date, :end_date, :class_days, :importing_cohort_id)
  end
end
