class AssessmentReportsController < ApplicationController
  def show
    @assessment = Assessment.find(params[:assessment_id])
    @cohort = current_cohort
    authorize! :manage, @assessment
  end
end
