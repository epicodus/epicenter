class CourseExportController < ApplicationController

  def show
    authorize! :manage, Course
    course = Course.find(params[:course_id])
    filename = Rails.root.join('tmp','students.txt')
    course.export_students_emails(filename)
    send_file(filename)
  end

end
