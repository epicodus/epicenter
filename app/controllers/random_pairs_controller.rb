class RandomPairsController < ApplicationController

  include WeekdayHelper

  before_filter :authenticate_student!

  def show
    if is_weekday?
      @grade_students = current_student.similar_grade_students
      @random_pair = @grade_students.sample(rand(@grade_students.count)).first
    else
      redirect_to root_path
    end
  end
end
