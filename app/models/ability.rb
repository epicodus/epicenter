class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.is_a? Admin
      can :manage, Assessment
      can :read, Submission
      can :create, Review
      can :read, CohortAttendanceStatistics
    elsif user.is_a? Student
      can :read, Assessment
      can :create, Submission
      can :update, Submission, student_id: user.id
      can :create, BankAccount
      can :create, CreditCard
      can :create, Payment, payment_method: { student_id: user.id }
      can :read, Payment, student_id: user.id
      can :update, Verification, bank_account: { student_id: user.id }
      can :read, StudentAttendanceStatistics, student: user
    else
      raise CanCan::AccessDenied.new("You need to sign in.", :manage, :all)
    end
  end
end
