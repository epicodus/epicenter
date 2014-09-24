class RequirementsController < ApplicationController

  def index
  end

  def new
    @assessment = Assessment.find(params[:assessment_id])
    @requirement = @assessment.requirements.new
  end

  def create
    @assessment = Assessment.find(params[:assessment_id])
    @requirement = @assessment.requirements.new(requirement_params)
    if @requirement.save
      respond_to do |format|
        format.html { redirect_to @assessment }
        format.js
      end
    end
  end

  def edit
    @assessment = Assessment.find(params[:assessment_id])
    @requirement = @assessment.requirements.find(params[:id])
  end

  def update
    @assessment = Assessment.find(params[:assessment_id])
    @requirement = @assessment.requirements.find(params[:id])
    if @requirement.update(requirement_params)
      respond_to do |format|
        format.html { redirect_to @assessment }
        format.js
      end
    end
  end

  def destroy
    @assessment = Assessment.find(params[:assessment_id])
    @requirement = @assessment.requirements.find(params[:id])
    if @requirement.destroy
      respond_to do |format|
        format.html { redirect_to @assessment }
        format.js
      end
    end
  end

private

  def requirement_params
    params.require(:requirement).permit(:content, :assessment_id)
  end
end
