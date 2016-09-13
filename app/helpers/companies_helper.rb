module CompaniesHelper
  def determine_internship_courses(internship, &block)
    if params[:previous]
      internship.courses.inactive_courses.reverse(&block)
    else
      internship.courses.active_courses.reverse(&block)
    end
  end
end
