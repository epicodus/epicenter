class CohortsController < ApplicationController
  authorize_resource

  def new
    @cohort = Cohort.new(start_time: "9:00 AM", end_time: "5:00 PM")
  end

  def create
    @cohort = Cohort.new(cohort_params)
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
    params[:cohort][:class_days] = params[:cohort][:class_days].split(',').map { |day| Date.parse(day) }
    params.require(:cohort).permit(:description, :importing_cohort_id, :start_time, :end_time, class_days: [])
  end
end
