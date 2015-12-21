class Ability
  include CanCan::Ability

  def initialize(user, ip)
    user ||= User.new

    if user.is_a? Admin
      can :manage, AttendanceRecord
      can :manage, CodeReview
      can :manage, Course
      can :manage, Company
      can :manage, Internship
      can :read, Submission
      can :create, Review
      can :read, CourseAttendanceStatistics
      can :create, AttendanceRecordAmendment
      can :read, Student
    elsif user.is_a?(Student) && user.courses.any?
      can :read, CodeReview, course_id: user.course_id
      can :create, Submission, student_id: user.id
      can :update, Submission, student_id: user.id
      can :create, BankAccount
      can :update, BankAccount
      can :read, Course, id: user.course_id
      can :create, CreditCard
      can :create, Payment, student_id: user.id, payment_method: { student_id: user.id }
      can :read, Payment, student_id: user.id
      can :read, StudentAttendanceStatistics, student: user
      can :read, Internship, course_id: user.course_id
      can :read, Transcript, student: user
      can :read, :certificate
      can :manage, AttendanceRecord if is_local(ip)
    elsif user.is_a?(Student) && user.courses.empty?
      can :create, BankAccount
      can :update, BankAccount
      can :create, CreditCard
      can :create, Payment, student_id: user.id, payment_method: { student_id: user.id }
      can :read, Payment, student_id: user.id
    elsif is_local(ip)
      can [:create, :update], AttendanceRecord
    else
      raise CanCan::AccessDenied.new("You need to sign in.", :manage, :all)
    end
  end

  private

  def local_ip_ranges
    %w{::1}
  end

  def is_local(ip)
    require 'ipaddr'
    ip = IPAddr.new(ip)
    local_ip_ranges.any? { |range| IPAddr.new(range).include?(ip) }
  end
end
