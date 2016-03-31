class InvitationsController < Devise::InvitationsController

  def create
    if params[:student_id]
      resend_invitation
    else
      super
      set_flash_for_student
    end
  end

  def after_invite_path_for(user)
    root_path
  end

private

  def resend_invitation
    student = Student.find(params[:student_id])
    student.invite!
    redirect_to root_path, notice: "A new invitation email has been sent to #{student.email}"
  end

  def set_flash_for_student
    if resource.errors.empty?
      student = Student.find_by(email: params[:student][:email])
      course = Course.find(params[:student][:course_id])
      flash[:notice] = "An invitation email has been sent to #{student.email} to join #{course.description}. #{view_context.link_to('Wrong course?', student_courses_path(student))}"
    end
  end
end
