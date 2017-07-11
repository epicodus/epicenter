class Cohort < ApplicationRecord
  validates :start_date, presence: true, uniqueness: { scope: [:office_id, :track_id] }
  validates :office, presence: true

  default_scope { order(:start_date) }

  has_and_belongs_to_many :courses, -> { order(:end_date) }, after_add: :update_end_date
  belongs_to :office
  belongs_to :track
  belongs_to :admin

  before_create :set_description, if: ->(cohort) { cohort.description.blank? }
  after_create :find_or_create_courses, if: ->(cohort) { cohort.courses.empty? }

  def self.cohorts_for(office)
    includes(:office).where(offices: { name: office.name })
  end

  def self.previous_cohorts
    where('end_date < ?', Time.zone.now.to_date).order(:description)
  end

  def self.current_cohorts
    today = Time.zone.now.to_date
    where('start_date <= ? AND end_date >= ?', today, today)
  end

  def self.future_cohorts
    where('start_date > ?', Time.zone.now.to_date)
  end

  def find_or_create_courses
    next_course_start_date = start_date
    5.times do |level|
      course = Course.find_or_create_by({ language: track.languages.find_by(level: level), start_date: skip_holidays(next_course_start_date), office: office, track: track, start_time: '8:00 AM', end_time: '5:00 PM' }) do |course|
        course.admin = admin
        course.save
      end
      next_course_start_date = course.end_date.next_week
      self.courses << course
    end
  end

private
  def update_end_date(course)
    update(end_date: course.end_date) if self.end_date.nil? || course.end_date > self.end_date
  end

  def skip_holidays(day)
    while day.saturday? || day.sunday? || Rails.configuration.holidays.include?(day.strftime('%Y-%m-%d')) || Rails.configuration.holiday_weeks.include?(day.monday.strftime('%Y-%m-%d')) do
      day = day.next
    end
    day
  end

  def set_description
    self.description = "#{start_date.strftime('%Y-%m')} #{track.description} #{office.name}"
  end
end
