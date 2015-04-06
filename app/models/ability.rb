class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.is_a? Admin
      can :manage, AttendanceRecord
      can :manage, Assessment
      can :manage, Cohort
      can :manage, Company
      can :read, Submission
      can :create, Review
      can :read, CohortAttendanceStatistics
      can :create, AttendanceRecordAmendment
    elsif user.is_a? Student
      can :read, Assessment, cohort_id: user.cohort_id
      can :create, Submission, student_id: user.id
      can :update, Submission, student_id: user.id
      can :create, BankAccount
      can :read, Cohort, id: user.cohort_id
      can :create, CreditCard
      can :create, Payment, student_id: user.id, payment_method: { student_id: user.id }
      can :read, Payment, student_id: user.id
      can :update, Verification, bank_account: { student_id: user.id }
      can :read, StudentAttendanceStatistics, student: user
    else
      raise CanCan::AccessDenied.new("You need to sign in.", :manage, :all)
    end
  end
end
