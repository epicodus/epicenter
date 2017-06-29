class RandomPairsController < ApplicationController

  before_action :authenticate_student!

  def show
    @random_pairs = current_student.random_pairs
  end
end
