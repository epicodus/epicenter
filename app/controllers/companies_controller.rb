class CompaniesController < ApplicationController

  def show
    @company = Company.find(params[:id])
    @course_internship = CourseInternship.new
    authorize! :manage, @company
  end
end
