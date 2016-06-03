class Course < ActiveRecord::Base
  scope :internship_courses, -> { where(internship_course: true) }
  scope :non_internship_courses, -> { where(internship_course: false) }
  scope :previous_courses, -> { where('end_date <= ?', Time.zone.now.to_date) }

  validates :description, :start_date, :end_date, :start_time, :end_time, presence: true
  before_validation :set_start_and_end_dates

  belongs_to :admin
  has_many :enrollments
  has_many :students, through: :enrollments
  has_many :attendance_records, through: :students
  has_many :code_reviews
  has_many :course_internships
  has_many :internships, through: :course_internships

  serialize :class_days, Array

  attr_accessor :importing_course_id

  before_create :import_code_reviews
  after_destroy :reassign_admin_current_courses

  def self.active_internship_courses
    unscoped.where(internship_course: true, active: true).order(:description)
  end

  def self.inactive_internship_courses
    unscoped.where(internship_course: true, active: false).order(:description)
  end

  def self.with_code_reviews
    includes(:code_reviews).where.not(code_reviews: { id: nil })
  end

  def self.current_and_future_courses
    today = Time.zone.now.to_date
    where('start_date <= ? AND end_date >= ? OR start_date >= ?', today, today, today).order(:description)
  end

  def total_internship_students_requested
    internships.pluck(:number_of_students).compact.sum
  end

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

  def realize_tuition
    students.each do |student|
      payment_amount = (credit_cost * (student.plan.total_amount / student.plan.credits)) / 100
      RestClient::Request.execute(
        url: "https://epicodus.lessaccounting.com/payments.json?api_key=#{ENV['LESS_ACCOUNTING_API_KEY']}&payment[title]=#{student.name}&payment[amount]=#{payment_amount}&payment[date]=#{Date.today.strftime('%Y-%m-%d')}&payment[bank_account_id]=120215&payment[expense_category_id]=1496063&payment[payment_type]=expense%20refund",
        method: :post,
        user: ENV['LESS_ACCOUNTING_EMAIL'],
        password: ENV['LESS_ACCOUNTING_PASSWORD']
      )
    end
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
