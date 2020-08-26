require 'csv'

class Course < ApplicationRecord
  default_scope { order(:start_date) }

  scope :fulltime_courses, -> { where(parttime: false) }
  scope :parttime_courses, -> { where(parttime: true) }
  scope :internship_courses, -> { where(internship_course: true) }
  scope :non_internship_courses, -> { where(internship_course: false) }
  scope :non_online_courses, -> { where.not('description LIKE ?', '%ONLINE%') }
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

  def self.current_and_previous_courses
    where('start_date <= ?', Time.zone.now.to_date).order(:start_date)
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
    track_name = " [#{track.description} track]" if track.present? && !internship_course? && !parttime?
    "#{office.name} - #{description} (#{teacher})#{track_name}"
  end

  def description_and_office
    "#{description} (#{office.name})"
  end

  def start_time_today(leeway=0)
    the_start_time = Time.zone.now.to_date.sunday? ? '9:00 AM' : start_time
    the_start_time.in_time_zone(office.time_zone) - leeway.minutes
  end

  def end_time_today(leeway=0)
    the_end_time = Time.zone.now.to_date.sunday? ? '3:00 PM' : end_time
    the_end_time.in_time_zone(office.time_zone) + leeway.minutes
  end

  def in_session?
    start_date <= Time.zone.now.to_date && end_date >= Time.zone.now.to_date
  end

  def is_class_day?
    class_days.include?(Time.zone.now.in_time_zone(office.time_zone).to_date)
  end

  def other_course_students(student)
    students.where.not(id: student.id).order(:name)
  end

  def other_students
    Student.where.not(id: students.map(&:id)).order(:name)
  end

  def courses_all_locations
    Course.where(start_date: start_date).where(end_date: end_date)
  end

  def students_all_locations
    Student.where(id: courses_all_locations.map {|c| c.students}.flatten)
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
    if language.name == "Internship"
      tracks = cohorts.map { |cohort| cohort.track.description }.sort.join(", ")
      self.description = "#{start_date.strftime('%Y-%m')} Internship (#{tracks})"
    else
      self.description = "#{start_date.strftime('%Y-%m')} #{language.name}"
    end
  end

private

  def set_start_and_end_dates
    self.start_date = class_days.sort.first
    self.end_date = class_days.sort.last
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
    self.parttime = language.name.downcase.include?('evening') || language.name.downcase.include?('part-time')
    true
  end

  def set_internship_course
    self.internship_course = language.name.downcase.include? "internship"
    true
  end

  def update_cohort_end_date(cohort)
    cohort.update(end_date: end_date) if cohort.end_date.nil? || self.end_date > cohort.end_date
  end

  def set_class_days
    if language.name.include?('part-time track')
      days = [0,2,4]
    elsif language.parttime?
      days = [2,4]
    else
      days = [1,2,3,4,5]
    end
    class_days = []
    day = start_date.beginning_of_week
    language.number_of_days.times do
      while !days.include?(day.wday) || (language.skip_holiday_weeks? && Rails.configuration.holiday_weeks.include?(day.strftime('%Y-%m-%d')))
        if language.skip_holiday_weeks? && Rails.configuration.holiday_weeks.include?(day.strftime('%Y-%m-%d'))
          day = day.next_week
        else
          day = day.next
        end
      end
      class_days << day unless Rails.configuration.holidays.include?(day.strftime('%Y-%m-%d'))
      day = day.next
    end
    self.class_days = class_days
  end
end
