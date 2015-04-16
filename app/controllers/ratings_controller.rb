class RatingsController < ApplicationController

  def create
    rating = current_student.ratings.new(rating_params)
    if rating.save
    else
      rating = Rating.where(internship_id: params[:internship_id], student: current_student).first
      rating.update(rating_params)
    end
    redirect_to :back
  end


  private

  def rating_params
    { interest: params[:commit].keys.first.to_i, internship_id: params[:internship_id], notes: params[:notes] }
  end
end
