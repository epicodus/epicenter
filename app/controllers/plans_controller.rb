class PlansController < ApplicationController
  def update
    @course = Course.find(params[:course_id])
    if current_admin.try(:super_admin)
      @course.change_intro_payment_plans_to_upfront
      redirect_to course_path(@course), notice: "All students still on the intro payment plan in this course have been switched to the upfront payment plan."
    else
      redirect_to course_path(@course), alert: "You are not authorized to access this page."
    end
  end
end
