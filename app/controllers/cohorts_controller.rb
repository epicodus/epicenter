class CohortsController < ApplicationController
  authorize_resource

  def new
    @cohort = Cohort.new
  end

  def create
    @cohort = Cohort.new(cohort_params)
    if @cohort.save
      current_admin.update(current_cohort: @cohort)
      redirect_to cohort_assessments_path(@cohort), notice: 'Class has been created!'
    else
      render :new
    end
  end

private

  def cohort_params
    params.require(:cohort).permit(:description, :start_date, :end_date, :importing_cohort_id)
  end
end
