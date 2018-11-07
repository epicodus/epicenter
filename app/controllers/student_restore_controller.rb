class StudentRestoreController < ApplicationController

  def update
    authorize! :manage, Enrollment
    student = Student.only_deleted.find(params[:student_id])
    if params[:restore]
      student.restore
      redirect_to student_courses_path(student), notice: "#{student.name} has been restored."
    elsif params[:expunge]
      student.crm_lead.update({ 'custom.Epicenter - ID': nil })
      student.really_destroy!
      redirect_to root_path, alert: "#{student.name} has been expunged."
    end
  end

end
