class AssessmentReportsController < ApplicationController
  def show
    @assessment = Assessment.find(params[:assessment_id])
    authorize! :manage, @assessment
  end
end
