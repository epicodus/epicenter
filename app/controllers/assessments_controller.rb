class AssessmentsController < ApplicationController

  def index
    @assessments = Assessment.all
    @submission = Submission.new
    authorize! :read, @assessments
  end

  def new
    @assessment = Assessment.new
    authorize! :create, @assessment
  end

  def create
    @assessment = Assessment.new(assessment_params)
    if @assessment.save
      redirect_to assessments_url, notice: "Assessment added!"
    else
      render 'new'
    end
    authorize! :create, @assessment
  end

  def show
    @grade = Grade.new
    @assessment = Assessment.find(params[:id])
    authorize! :read, @assessment
  end

  def edit
    @assessment = Assessment.find(params[:id])
    authorize! :update, @assessment
  end

  def update
    @assessment = Assessment.find(params[:id])
    if @assessment.update(assessment_params)
      redirect_to assessments_url, notice: "Assessment updated!"
    else
      render 'new'
    end
    authorize! :update, @assessment
  end

  def destroy
    authorize! :destroy, @assessment
    @assessment = Assessment.find(params[:id])
    @assessment.destroy
    flash[:notice] = "Assessment deleted."
    redirect_to assessments_path
  end

private

  def assessment_params
    params.require(:assessment).permit(:title, :section, :url)
  end
end
