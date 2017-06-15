class InvitationsController < Devise::InvitationsController

  def create
    if params[:student_id]
      resend_invitation
    else
      email = params[:student][:email]
      response = Student.pull_info_from_crm(email)
      if response[:name] && response[:course_id]
        params[:student][:name] = response[:name]
        params[:student][:course_id] = response[:course_id]
        super
        set_starting_cohort
        enroll_in_cohort(Cohort.find(response[:cohort_id])) if response[:cohort_id]
        set_flash_for_student
      else
        redirect_to new_student_invitation_path, alert: response[:errors].to_s
      end
    end
  end

  def after_invite_path_for(_)
    root_path
  end

private

  def resend_invitation
    student = Student.find(params[:student_id])
    student.invite!
    redirect_to root_path, notice: "A new invitation email has been sent to #{student.email}"
  end

  def set_starting_cohort
    student = Student.find_by(email: params[:student][:email])
    student.update(starting_cohort_id: student.courses_with_withdrawn.fulltime_courses.first.try(:id))
  end

  def enroll_in_cohort(cohort)
    cohort.courses.each do |course|
      resource.courses << course unless resource.courses.include? course
    end
  end

  def set_flash_for_student
    if resource.errors.empty?
      student = Student.find_by(email: params[:student][:email])
      course = Course.find(params[:student][:course_id])
      flash[:notice] = "An invitation email has been sent to #{student.email} to join #{course.description} in #{course.office.name}. #{view_context.link_to('Wrong course?', student_courses_path(student))}"
    end
  end
end
