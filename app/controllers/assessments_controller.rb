class AssessmentsController < ApplicationController

  def index
    @assessments = Assessment.all
  end

  def new
    @assessment = Assessment.new
    3.times { @assessment.requirements.build }
  end

  def create
    @assessment = Assessment.new(assessment_params)
    if @assessment.save
      redirect_to @assessment, notice: "Assessment has been saved!"
    else
      render 'new'
    end
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
    params.require(:assessment).permit(:title, :section, :url, requirements_attributes: [:content])
  end
end
