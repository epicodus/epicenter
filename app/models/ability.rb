class Ability
  include CanCan::Ability

  def initialize(user)
    if user.admin?
      can :manage, :all
    else
      can :read, :all
      # can [:create, :update, :destroy], Submission
    end
  end
end
