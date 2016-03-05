class CompaniesController < ApplicationController
  authorize_resource

  def index
    @companies = Company.all
  end

  def show
    @company = Company.find(params[:id])
    authorize! :manage, @company
  end

  def update
    @company = Company.find(params[:id])
    if @company.update(company_params)
      flash[:notice] = "#{@company.name} updated"
      redirect_to companies_path
    else
      render 'edit'
    end
  end

  private
    def company_params
      params.require(:company).permit()
    end
end
