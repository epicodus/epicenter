class RatingsController < ApplicationController

  def create
    rating = Rating.for(Internship.find(params[:internship_id]), current_student)
    rating.update(rating_params)
    redirect_to :back
  end


  private

  def rating_params
    { interest: params[:commit].keys.first.to_i, internship_id: params[:internship_id], notes: params[:notes] }
  end
end
