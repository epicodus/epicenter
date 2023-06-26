class Admin < User
  default_scope { order(:name) }
  scope :teachers, -> { where(teacher: true) }

  belongs_to :current_course, class_name: 'Course', optional: true
  has_many :courses
  has_many :cohorts
  has_many :submissions
  has_many :reviews
  has_many :checkins, foreign_key: 'admin_id', class_name: 'Checkin'

  before_validation :assign_current_course, on: :create
  include DeviseInvitable::Inviter

  def other_courses
    Course.where.not(id: courses.map(&:id)).includes(:admin).includes(:office)
  end

  def current_course
    super || courses.last
  end

private

  def assign_current_course
    self.current_course = Course.last
  end
end
