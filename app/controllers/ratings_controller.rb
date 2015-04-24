class RatingsController < ApplicationController

  def create
    rating = current_student.ratings.new(rating_params)
    if rating.save
    else
      internship = internship.find(params[:internship_id])
      rating = Rating.for(internship, current_student)
      rating.update(rating_params)
    end
    redirect_to :back
  end


  private

  def rating_params
    { interest: params[:commit].keys.first.to_i, internship_id: params[:internship_id], notes: params[:notes] }
  end
end
