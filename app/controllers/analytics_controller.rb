class AnalyticsController < ApplicationController
  def index
    @submissions = Submission.all
    @assessments = Assessment.all
    @students = User.students
  end
end
