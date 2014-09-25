class AnalyticsController < ApplicationController
  def index
    @assessments = Assessment.all
    @students = User.students
  end
end
