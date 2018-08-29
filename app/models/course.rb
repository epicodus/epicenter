require 'csv'

class Course < ApplicationRecord
  scope :fulltime_courses, -> { where(parttime: false) }
  scope :parttime_courses, -> { where(parttime: true) }
  scope :internship_courses, -> { where(internship_course: true) }
  scope :non_internship_courses, -> { where(internship_course: false) }
  scope :active_courses, -> { where(active: true).order(:description) }
  scope :inactive_courses, -> { where(active: false).order(:description) }
  scope :full_internship_courses, -> { where(full: true).order(:description) }
  scope :available_internship_courses, -> { where(full: nil).or(where(full: false)).order(:description) }
  scope :level, -> (level) { joins(:language).where('level = ?', level) }

  validates :language_id, :start_date, :end_date, :start_time, :end_time, :office_id, presence: true
  before_validation :set_class_days, if: ->(course) { course.class_days.empty? && course.start_date }
  before_validation :set_start_and_end_dates
  before_create :set_parttime
  before_create :set_internship_course
  before_create :set_description, if: ->(course) { course.description.blank? }

  belongs_to :admin, optional: true
  belongs_to :office
  belongs_to :language
  belongs_to :track, optional: true
  has_and_belongs_to_many :cohorts, after_add: :update_cohort_end_date
  has_many :enrollments
  has_many :students, through: :enrollments
  has_many :attendance_records, through: :students
  has_many :code_reviews
  has_many :course_internships
  has_many :internships, through: :course_internships
  has_many :interview_assignments
  has_many :internship_assignments

  serialize :class_days, Array

  attr_accessor :importing_course_id

  before_create :import_code_reviews
  after_destroy :reassign_admin_current_courses

  def self.courses_for(office)
    includes(:office).where(offices: { name: office.name })
  end

  def self.active_internship_courses
    unscoped.where(internship_course: true, active: true).order(:description)
  end

  def self.inactive_internship_courses
    unscoped.where(internship_course: true, active: false).order(:description)
  end

  def self.with_code_reviews
    includes(:code_reviews).where.not(code_reviews: { id: nil })
  end

  def self.previous_courses
    where('end_date < ?', Time.zone.now.to_date).includes(:admin).order(:description)
  end

  def self.current_courses
    today = Time.zone.now.to_date
    where('start_date <= ? AND end_date >= ?', today, today).includes(:admin).order(:description)
  end

  def self.future_courses
    where('start_date > ?', Time.zone.now.to_date).includes(:admin).order(:description)
  end

  def self.current_and_future_courses
    today = Time.zone.now.to_date
    where('start_date <= ? AND end_date >= ? OR start_date >= ?', today, today, today).order(:description)
  end

  def self.total_class_days_until(date)
    all.map(&:class_days).flatten.select { |day| day <= date }.sort.reverse
  end

  def total_internship_students_requested
    internships.pluck(:number_of_students).compact.sum
  end

  def teacher
    admin ? admin.name : 'Unknown teacher'
  end

  def teacher_and_description
    "#{office.name} - #{description} (#{teacher})"
  end

  def description_and_office
    "#{description} (#{office.name})"
  end

  def in_session?
    start_date <= Time.zone.now.to_date && end_date >= Time.zone.now.to_date
  end

  def is_class_day?
    class_days.include?(Time.zone.now.in_time_zone(office.time_zone).to_date)
  end

  def other_course_students(student)
    students.where.not(id: student.id)
  end

  def other_students
    Student.where.not(id: students.map(&:id)).order(:name)
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

  def export_students_emails(filename)
    File.open(filename, 'w') do |file|
      students.each do |student|
        file.puts student.email
      end
    end
  end

  def set_description
    if language.name == "Intro" && track.present?
      self.description = "#{start_date.strftime('%Y-%m')} Intro #{track.languages.find_by(level: 1).name}"
    elsif language.name == "Internship"
      tracks = cohorts.map { |cohort| cohort.track.description }.sort.join(", ")
      self.description = "#{start_date.strftime('%Y-%m')} Internship (#{tracks})"
    elsif language.level == 0 && office.name != "Portland" && office.name != 'Online'
      self.description = "#{start_date.strftime('%Y-%m')} #{language.name} #{office.name.upcase}"
    else
      self.description = "#{start_date.strftime('%Y-%m')} #{language.name}"
    end
  end

  def change_intro_payment_plans_to_upfront
    students_to_update = students.where(plan: Plan.active.intro.first)
    students_to_update.each do |student|
      student.update(plan: Plan.active.fulltime_upfront.first)
    end
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Payment plans updated to upfront",
        :text => students_to_update.map { |student| student.name }.join("\n")
      })
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

  def set_parttime
    self.parttime = language.name.downcase.include?('evening') || language.name == 'Online'
    return true
  end

  def set_internship_course
    self.internship_course = language.name.downcase.include? "internship"
    return true
  end

  def update_cohort_end_date(cohort)
    cohort.update(end_date: end_date) if cohort.end_date.nil? || self.end_date > cohort.end_date
  end

  def set_class_days
    class_days = []
    day = start_date.beginning_of_week
    language.number_of_days.times do
      while day.saturday? || day.sunday? || (language.skip_holiday_weeks? && Rails.configuration.holiday_weeks.include?(day.strftime('%Y-%m-%d'))) do
        day = day.next_week
      end
      while language.parttime? && !(day.monday? || day.wednesday?)
        day = day.next
      end
      while language.online? && !(day.tuesday? || day.wednesday? || day.thursday?)
        day = day.next
      end
      class_days << day unless Rails.configuration.holidays.include? day.strftime('%Y-%m-%d')
      day = day.next
    end
    self.class_days = class_days
  end
end
