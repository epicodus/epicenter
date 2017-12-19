class SurveysController < ApplicationController
  def index
    @code_review = CodeReview.find(params[:code_review_id])
    @surveys = @code_review.surveys
    redirect_to root_path, alert: "You do not have permission to view this page." unless current_admin.try(:can_view_survey_results)
  end

  def show
    @survey = Survey.find(params[:id])
    redirect_to root_path, alert: "You do not have permission to view this page." unless current_admin.try(:can_view_survey_results)
  end

  def create
    binding.pry
  end
end
