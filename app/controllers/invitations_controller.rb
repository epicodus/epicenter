class InvitationsController < Devise::InvitationsController

  def create
    if params[:student_id]
      resend_invitation
    else
      email = params[:student][:email]
      if User.find_by(email: email)
        redirect_to new_student_invitation_path, alert: "Email already used in Epicenter"
      else
        begin
          crm_lead = CrmLead.new(email)
          name = crm_lead.name
          first_course = crm_lead.first_course
          cohort = crm_lead.cohort
        rescue CrmError => e
          redirect_to new_student_invitation_path, alert: e.message and return
        end
        params[:student][:name] = name
        params[:student][:course_id] = first_course.id
        super
        resource.update(office: first_course.office)
        enroll_in_cohort(cohort) if cohort
        set_flash_for_student
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
