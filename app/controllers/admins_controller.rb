class AdminsController < ApplicationController
  def update
    @admin = Admin.find(params[:id])
    if @admin.update(admin_params)
      redirect_to current_course_path(@admin.current_course), notice: "You have switched to #{@admin.current_course.description}."
    else
      redirect_to current_course_path(@admin.current_course), alert: "Something went wrong."
    end
  end

private

  def admin_params
    params.require(:admin).permit(:current_course_id)
  end

  def current_course_path(course)
    course_referer = request.referer[/courses\/\d+\/(.*)/, 1]
    if respond_to? "course_#{course_referer}_path"
      send("course_#{course_referer}_path", course)
    elsif respond_to? "#{course_referer}_course_path"
      send("#{course_referer}_course_path", course)
    else
      :back
    end
  end
end
