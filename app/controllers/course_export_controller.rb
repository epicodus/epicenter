class CourseExportController < ApplicationController

  def show
    authorize! :manage, Course
    course = Course.find(params[:course_id])
    if params[:ratings]
      filename = Rails.root.join('tmp','ratings.txt')
      course.export_internship_ratings(filename)
    else
      filename = Rails.root.join('tmp','students.txt')
      course.export_students_emails(filename)
    end
    send_file(filename)
  end

end
