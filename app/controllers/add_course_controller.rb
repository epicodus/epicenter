class AddCourseController < ApplicationController
  def update
    authorize! :manage, Student
    student = Student.find(params[:student_id])
    if Office.all.map{|o| o.short_name}.include? params[:option]
      office = Office.find_by(short_name: params[:option])
      @courses = student.other_courses.current_and_future_courses.courses_for(office).order(:description).reverse
      @descriptor = office.short_name
    else
      @courses = student.other_courses.previous_courses.order(:description).reverse
      @descriptor = 'previous'
    end
    render 'students/add_course'
  end
end
