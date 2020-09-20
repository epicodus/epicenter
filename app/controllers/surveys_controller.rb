class SurveysController < ApplicationController
  before_action :authenticate_admin!

  def create
    @survey = Survey.new(input: params[:url])
    @code_reviews = CodeReview.where(survey: @survey.url)
    if @survey.url && @code_reviews.any?
      :create
    elsif @survey.url.nil?
      redirect_to new_survey_path, alert: 'Invalid survey URL'
    elsif @code_reviews.empty?
      redirect_to new_survey_path, alert: 'No code reviews found with visible_date set to this week'
    end
  end
end
