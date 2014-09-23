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

  def show
    @assessment = Assessment.find(params[:id])
  end

  def edit
    @assessment = Assessment.find(params[:id])
  end

  def update
    @assessment = Assessment.find(params[:id])
    if @assessment.update(assessment_params)
      redirect_to assessments_url, notice: "Assessment updated!"
    else
      render 'new'
    end
  end

  def destroy
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
