class SpecialPermissionsController < ApplicationController
  before_action :authenticate_admin!

  def create
    @special_permission = SpecialPermission.new(special_permission_params)
    code_review = @special_permission.code_review
    student = @special_permission.student
    if @special_permission.save
      redirect_to course_student_path(code_review.course, student), notice: "#{code_review.title} made visible for #{student.name}"
    else
      render :new
    end
  end

  def destroy
    @special_permission = SpecialPermission.find(params[:id])
    code_review = @special_permission.code_review
    student = @special_permission.student
    @special_permission.destroy
    redirect_to course_student_path(code_review.course, student), alert: "#{code_review.title} visibility marker removed for #{student.name}"
  end

  private

  def special_permission_params
    params.require(:special_permission).permit(:student_id, :code_review_id)
  end
end
