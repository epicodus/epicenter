class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.is_a? Admin
      can :manage, AttendanceRecord
      can :manage, CodeReview
      can :manage, Cohort
      can :manage, Company
      can :manage, Internship
      can :read, Submission
      can :create, Review
      can :read, CohortAttendanceStatistics
      can :create, AttendanceRecordAmendment
      can :read, Student
    elsif user.is_a? Student
      can :read, CodeReview, cohort_id: user.cohort_id
      can :create, Submission, student_id: user.id
      can :update, Submission, student_id: user.id
      can :create, BankAccount
      can :read, Cohort, id: user.cohort_id
      can :create, CreditCard
      can :create, Payment, student_id: user.id, payment_method: { student_id: user.id }
      can :read, Payment, student_id: user.id
      can :update, Verification, bank_account: { student_id: user.id }
      can :read, StudentAttendanceStatistics, student: user
      can :read, Internship, cohort_id: user.cohort_id
    else
      raise CanCan::AccessDenied.new("You need to sign in.", :manage, :all)
    end
  end
end
