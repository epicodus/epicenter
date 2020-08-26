class Ability
  include CanCan::Ability

  def initialize(user, ip)
    user ||= User.new

    if user.is_a? Admin
      set_admin_permissions
    elsif user.is_a?(Student) && user.courses.any?
      set_enrolled_student_permissions(user, ip)
    elsif user.is_a?(Student) && user.courses.empty?
      set_unenrolled_student_permissions(user)
    elsif user.is_a? Company
      set_company_permissions(user)
    elsif IpLocation.is_local?(ip)
      can [:create, :update], AttendanceRecord
    else
      raise CanCan::AccessDenied.new("You need to sign in.", :manage, :all)
    end
  end

private

  def set_admin_permissions
    can :manage, [AttendanceRecord, CodeReview, Company, Course, Enrollment,
                  Internship, InternshipAssignment, InterviewAssignment,
                  Payment, Student, Submission, Cohort, CostAdjustment, DailySubmission]
    can :manage, [AttendanceRecordAmendment, Review]
    can :read, [Transcript, PeerEvaluation, PairFeedback]
    can :read, :certificate
  end

  def set_enrolled_student_permissions(user, ip)
    can [:create, :update], BankAccount
    can [:create, :update], Submission, student_id: user.id
    can [:read, :create], DailySubmission, student_id: user.id
    can :manage, AttendanceRecord, student_id: user.id
    can :read, CodeReview, course_id: user.course_id
    can :read, Course, id: user.courses.map(&:id)
    can :read, :certificate
    can :create, CreditCard
    can :read, Internship do |internship|
      internship.courses.include? user.internship_course
    end
    can :create, Payment, student_id: user.id, payment_method: { student_id: user.id }
    can :read, Payment, student_id: user.id
    can :manage, Student, id: user.id
    can :read, Transcript, student: user
    can [:read, :create], PeerEvaluation, evaluator_id: user.id
    can [:read], PeerEvaluation, evaluatee_id: user.id
    can [:read, :create], PairFeedback, student_id: user.id
  end

  def set_unenrolled_student_permissions(user)
    can [:create, :update], BankAccount
    can :create, CreditCard
    can :create, Payment, student_id: user.id, payment_method: { student_id: user.id }
    can :read, Payment, student_id: user.id
    can :manage, Student, id: user.id
    can :read, Course, id: user.courses.map(&:id)
  end

  def set_company_permissions(user)
    can :manage, Company, id: user.id
    can :manage, Internship, company_id: user.id
  end
end
