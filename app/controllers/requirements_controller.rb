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
  end

  def update
  end

  def destroy
  end

private

  def requirement_params
    params.require(:requirement).permit(:content, :assessment_id)
  end
end
