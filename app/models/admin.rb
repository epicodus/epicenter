class Admin < User
  belongs_to :current_course, class_name: 'Course'

  before_create :assign_current_course
  devise :database_authenticatable, :validatable
  include DeviseInvitable::Inviter

private

  def assign_current_course
    self.current_course = Course.last
  end
end
