class CompaniesController < ApplicationController

  def show
    @company = Company.find(params[:id])
    @internships = @company.internships.includes(courses: [:interview_assignments])
    @course_internship = CourseInternship.new
    authorize! :manage, @company
  end
end
