class CompaniesController < ApplicationController
  authorize_resource
  before_action :find_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.all
  end

  def show
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
      flash[:alert] = "Company not added"
      render :new
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      flash[:notice] = "#{@company.name} updated"
      redirect_to companies_path
    else
      flash[:alert] = "Something went wrong"
      render :edit
    end
  end

  def destroy
    @company.delete
    flash[:alert] = "Company deleted."
    redirect_to companies_path
  end

  private
    def find_company
      @company = Company.find params[:id]
    end

    def company_params
      params.require(:company).permit(:name, :description, :website, :address,
                     :contact_name, :contact_title, :contact_phone, :contact_email)
    end
end
