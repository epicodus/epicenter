class Cohort < ApplicationRecord
  validates :start_date, presence: true, uniqueness: { scope: [:office_id, :track_id] }
  validates :office, presence: true

  default_scope { order(:start_date) }

  has_and_belongs_to_many :courses, -> { order(:end_date) }, after_add: :update_end_date
  has_many :starting_cohort_students, class_name: :User, foreign_key: :starting_cohort_id
  has_many :students
  belongs_to :office
  belongs_to :track
  belongs_to :admin

  after_create :find_or_create_courses, if: ->(cohort) { cohort.courses.empty? }
  after_create :set_description, if: ->(cohort) { cohort.description.blank? }

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
    if track.description == 'Part-time'
      course = Course.find_or_create_by({ language: track.languages.first, start_date: start_date, office: office, track: track, start_time: '6:00 PM', end_time: '9:00 PM' })
      course.admin = course.admin || admin
      self.courses << course
    elsif track.description == 'Online'
      course = Course.find_or_create_by({ language: track.languages.first, start_date: start_date, office: office, track: track, start_time: '5:30 PM', end_time: '7:30 PM' })
      course.admin = course.admin || admin
      self.courses << course
    else
      next_course_start_date = start_date
      5.times do |level|
        course = Course.find_or_create_by({ language: track.languages.find_by(level: level), start_date: skip_holidays(next_course_start_date), office: office, track: track, start_time: '8:00 AM', end_time: '5:00 PM' }) do |course|
          course.admin = admin
          course.active = false if level == 4
          course.save
        end
        next_course_start_date = course.end_date.next_week
        self.courses << course
      end
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
    description = "#{start_date.strftime('%Y-%m')} #{office.short_name} #{track.description} (#{start_date.strftime('%b %-d')} - #{end_date.strftime('%b %-d')})"
    description = "PT: " + description if track.description == 'Part-time' || track.description == 'Online'
    update(description: description)
  end
end
