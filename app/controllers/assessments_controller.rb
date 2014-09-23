class AssessmentsController < ApplicationController

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

  def assessment_params
    params.require(:assessment).permit(:title, :section, :url)
  end
end
