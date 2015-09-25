class RandomPairsController < ApplicationController

  before_filter :authenticate_student!

  def show
    @random_pairs = current_student.random_pairs
  end
end
