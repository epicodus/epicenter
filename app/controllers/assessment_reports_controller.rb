class AssessmentReportsController < ApplicationController
  def index
    @assessment = Assessment.find(params[:assessment_id])
    @cohort = current_admin.current_cohort
  end
end
