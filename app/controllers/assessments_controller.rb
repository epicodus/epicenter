class AssessmentsController < ApplicationController

  def index
    @assessments = Assessment.all
  end

  def new
    @assessment = Assessment.new
  end

  def create
    @assessment = Assessment.new(assessment_params)
    if @assessment.save
      redirect_to assessments_url, notice: "Assessment added!"
    else
      render 'new'
    end
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
