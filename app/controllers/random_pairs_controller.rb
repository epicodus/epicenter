class RandomPairsController < ApplicationController

  include WeekdayHelper

  before_filter :authenticate_student!

  def show
    if is_weekday?
      @random_pairs = current_student.random_pairs
    else
      redirect_to root_path
    end
  end
end
