class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.is_a? Admin
      can :manage, :all
    elsif user.is_a? Student
      can :read, Assessment
      can :create, Submission
      can :update, Submission, student_id: user.id
    else
      raise CanCan::AccessDenied.new("You need to sign in.", :manage, :all)
    end
  end
end
