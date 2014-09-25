class StudentsController < ApplicationController
  def index
    @students = User.students
  end

  def show
    @student = User.find(params[:id])
    @submissions = Submission.all
    @student_submission = Submission.where(user_id: params[:id])
  end
end
