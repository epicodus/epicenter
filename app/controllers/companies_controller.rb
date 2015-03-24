class CompaniesController < ApplicationController
  authorize_resource

  def index
    @companies = Company.all
  end
end
