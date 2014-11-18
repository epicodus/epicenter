class AdminsController < ApplicationController
  def update
    @admin = Admin.find(params[:id])
    if @admin.update(admin_params)
      redirect_to current_cohort_path(@admin.current_cohort), notice: "You have switched to #{@admin.current_cohort.description}."
    else
      redirect_to current_cohort_path(@admin.current_cohort), alert: "Something went wrong."
    end
  end

private

  def admin_params
    params.require(:admin).permit(:current_cohort_id)
  end

  def current_cohort_path(cohort)
    cohort_referer = request.referer[/cohorts\/\d+\/(.*)/, 1]
    if respond_to? "cohort_#{cohort_referer}_path"
      send("cohort_#{cohort_referer}_path", cohort)
    elsif respond_to? "#{cohort_referer}_cohort_path"
      send("#{cohort_referer}_cohort_path", cohort)
    else
      :back
    end
  end
end
