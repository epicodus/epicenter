class RequirementsController < ApplicationController

  def index
  end

  def new
  end

  def create
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
