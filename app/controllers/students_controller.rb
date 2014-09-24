class StudentsController < ApplicationController
  def index
    # @students = [{id: 1, name: "Billy Bob", session: "Fall", completion: 35}, {id: 2, name: "Billy Jean", session: "Fall", completion: 20}, {id: 3, name: "Billy Joe", session: "Fall", completion: 90}]
    @students = User.students
  end

  def show
    # @student = {id: 1, name: "Billy Bob", session: "Fall", completion: 35}
    @student = User.find(params[:id])
    @submissions = Submission.all
    respond_to do |format|
      format.html
      format.js { render "show", :locals => {submission: params[:submission_id]} }
    end
  end
end
