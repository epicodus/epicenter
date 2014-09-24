class StudentsController < ApplicationController
  def index
    @students = [{id: 1, name: "Billy Bob", session: "Fall", completion: 35}, {id: 2, name: "Billy Jean", session: "Fall", completion: 20}, {id: 3, name: "Billy Joe", session: "Fall", completion: 90}]
  end

  def show
    @student = {id: 1, name: "Billy Bob", session: "Fall", completion: 35}
  end
end
