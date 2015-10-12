class RatingsController < ApplicationController

  def create
    @rating = Rating.for(Internship.find(params[:rating][:internship_id]), current_student)
    if @rating.update(rating_params)
      redirect_to course_internships_path(current_student.course)
    else
      @course = current_student.course
      @internships = @course.internships_sorted_by_interest(current_student)
      render 'internships/index'
    end
  end


  private

  def rating_params
    { interest: params[:rating][:interest].to_i, internship_id: params[:rating][:internship_id], notes: params[:rating][:notes] }
  end
end
