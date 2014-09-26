class AnalyticsController < ApplicationController
  def index
    @assessments = Assessment.all
    @students = User.students
  end

  def show
    @assessment = Assessment.find(params[:assessment_id])
  end
end
