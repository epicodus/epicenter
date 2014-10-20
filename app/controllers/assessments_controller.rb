class AssessmentsController < ApplicationController

  def index
    @assessments = Assessment.all
  end

  def new
  end

  def create
  end

  def show
    @assessment = Assessment.find(params[:id])
    @submission = @assessment.submission_for(current_user) || Submission.new(assessment: @assessment)
  end

  def edit
  end

  def update
  end

  def destroy
  end

private

  def assessment_params
    params.require(:assessment).permit(:title, :section, :url)
  end
end
