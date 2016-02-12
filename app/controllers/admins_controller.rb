class AdminsController < ApplicationController
  def update
    @admin = Admin.find(params[:id])
    if @admin.update(admin_params)
      redirect_to course_students_path(@admin.current_course), notice: "You have switched to #{@admin.current_course.description}."
    else
      redirect_to course_students_path(@admin.current_course), alert: "Something went wrong."
    end
  end

private

  def admin_params
    params.require(:admin).permit(:current_course_id)
  end
end
