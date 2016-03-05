class Course < ActiveRecord::Base
  default_scope { order(:start_date) }
  scope :with_code_reviews, -> { includes(:code_reviews).where.not(code_reviews: { id: nil }) }
  scope :current_and_future_courses, -> { where('start_date <= ? AND end_date >= ? OR start_date >= ?', Time.zone.now.to_date, Time.zone.now.to_date, Time.zone.now.to_date) }
  scope :previous_courses, -> { where('end_date <= ?', Time.zone.now.to_date) }

  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  before_validation :set_start_and_end_dates

  belongs_to :admin
  has_many :enrollments
  has_many :students, through: :enrollments
  has_many :attendance_records, through: :students
  has_many :code_reviews
  has_many :internships

  serialize :class_days, Array

  attr_accessor :importing_course_id

  before_create :import_code_reviews
  after_destroy :reassign_admin_current_courses

  def teacher
    admin ? admin.name : 'Unknown teacher'
  end

  def teacher_and_description
    "#{description} (#{teacher})"
  end

  def in_session?
    start_date <= Time.zone.now.to_date && end_date >= Time.zone.now.to_date
  end

  def other_course_students(student)
    students.where.not(id: student.id)
  end

  def other_students
    Student.where.not(id: students.map(&:id))
  end

  def number_of_days_since_start
    last_date = Time.zone.now.to_date <= end_date ? Time.zone.now.to_date : end_date
    class_dates_until(last_date).count
  end

  def total_class_days
    class_dates_until(end_date).count
  end

  def number_of_days_left
    total_class_days - number_of_days_since_start
  end

  def progress_percent
    (number_of_days_since_start.to_f / total_class_days.to_f) * 100
  end

  def class_dates_until(last_date)
    class_days.select { |day| day <= last_date }.sort
  end

private

  def set_start_and_end_dates
    self.start_date = class_days.select { |day| !day.saturday? && !day.sunday? }.sort.first
    self.end_date = class_days.select { |day| !day.saturday? && !day.sunday? }.sort.last
  end

  def import_code_reviews
    unless @importing_course_id.blank?
      self.code_reviews = Course.find(@importing_course_id).deep_clone(include: { code_reviews: :objectives }).code_reviews
    end
  end

  def reassign_admin_current_courses
    Admin.where(current_course_id: self.id).update_all(current_course_id: Course.last.id)
  end
end
