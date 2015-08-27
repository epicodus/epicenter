class RandomPairsController < ApplicationController

  before_filter :authenticate_student!

  def show
    @grade_students = current_student.similar_grade_students
    @random_pair = @grade_students.sample(rand(@grade_students.count)).first
  end
end
