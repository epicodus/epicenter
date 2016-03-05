class CompaniesController < ApplicationController
  authorize_resource

  def index
    @companies = Company.all
  end

  def show
    @company = Company.find(params[:id])
    authorize! :manage, @company
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      flash[:notice] = "#{@company.name} added to companies"
      redirect_to @company
    else
      render :new
    end
  end

  def edit
    @company = Company.find(params[:id])
  end

  def update
    @company = Company.find(params[:id])
    if @company.update(company_params)
      flash[:notice] = "#{@company.name} updated"
      redirect_to companies_path
    else
      flash[:alert] = "Something went wrong"
      render :edit
    end
  end

  def destroy
    @company = Company.find(params[:id])
    @company.delete
    flash[:alert] = "Company deleted."
    redirect_to companies_path
  end

  private
    def company_params
      params.require(:company).permit()
    end
end
