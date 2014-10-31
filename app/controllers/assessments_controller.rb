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
    @assessment = Assessment.find(params[:id])
  end

  def update
    @assessment = Assessment.find(params[:id])
    if @assessment.update(assessment_params)
      redirect_to @assessment, notice: "Assessment updated."
    else
      render 'edit'
    end
  end
  
private

  def assessment_params
    params.require(:assessment).permit(:title, :section, :url, requirements_attributes: [:id, :content, :_destroy])
  end
end
