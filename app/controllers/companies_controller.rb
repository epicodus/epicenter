class CompaniesController < ApplicationController

  def show
    @company = Company.find(params[:id])
    authorize! :manage, @company
  end
end
