require 'csv'

class Course < ApplicationRecord
  default_scope { order(:start_date) }

  scope :fulltime_courses, -> { where(parttime: false) }
  scope :parttime_intro_courses, -> { joins(:track).where("tracks.description IN (?)", ['Part-Time Intro to Programming', 'Part-Time Evening Intro to Programming']) }
  scope :parttime_js_react_courses, -> { joins(:track).where("tracks.description = 'Part-Time JS/React'") }
  scope :parttime_full_stack_courses, -> { joins(:track).where("tracks.description = 'Part-Time C#/React'") }
  scope :internship_courses, -> { where(internship_course: true) }
  scope :non_internship_courses, -> { where.not(id: internship_courses) }
  scope :non_fidgetech_courses, -> { where.not(description: 'Fidgetech') }
  scope :active_courses, -> { where(active: true).order(:description) }
  scope :inactive_courses, -> { where(active: false).order(:description) }
  scope :full_internship_courses, -> { where(full: true).order(:description) }
  scope :available_internship_courses, -> { where(full: nil).or(where(full: false)).order(:description) }
  scope :level, -> (level) { joins(:language).where('level = ?', level) }
  scope :current_cohort_courses, -> { joins(:cohort).where('cohorts.start_date <= ? AND cohorts.end_date >= ?', Time.zone.now.to_date, Time.zone.now.to_date) }

  validates :language_id, :start_date, :end_date, :office_id, presence: true

  before_validation :set_start_and_end_dates, on: :create, if: ->(course) { course.layout_file_path.blank? }
  before_update :set_start_and_end_dates
  before_update :set_description
  before_validation :build_course, on: :create, if: ->(course) { course.layout_file_path.present? && course.class_days.blank? }
  before_save :build_code_reviews, if: ->(course) { course.layout_file_path.present? && course.will_save_change_to_layout_file_path? } # relies on parttime being set correctly

  after_destroy :reassign_admin_current_courses

  belongs_to :admin, optional: true
  belongs_to :office
  belongs_to :language
  belongs_to :track, optional: true
  belongs_to :cohort
  has_many :enrollments
  has_many :students, through: :enrollments
  has_many :attendance_records, through: :students
  has_many :code_reviews
  has_many :course_internships
  has_many :internships, through: :course_internships
  has_many :interview_assignments
  has_many :internship_assignments
  has_and_belongs_to_many :class_times

  serialize :class_days, Array

  def self.cirr_parttime_courses
    # PT intro cohorts, PT JS/React cohorts, 2018-01 Online, and Fidgetech
    legacy_misc_courses = where(description: ['2018-01 Online', 'Fidgetech'])
    where(id: parttime_intro_courses + parttime_js_react_courses + legacy_misc_courses)
  end

  def self.cirr_fulltime_courses
    # FT and PT full-stack cohorts; exclude PT intro and PT JS/React cohorts
    where.not(id: cirr_parttime_courses)
  end

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

  def start_time(day = Time.zone.now.in_time_zone(office.time_zone).to_date)
    if ENV['ATTENDANCE_TEST_MODE'] == 'true'
      '00:00'
    else
      class_times.find_by(wday: day.wday).start_time
    end
  end

  def end_time(day = Time.zone.now.in_time_zone(office.time_zone).to_date)
    if ENV['ATTENDANCE_TEST_MODE'] == 'true'
      '23:59'
    else
      class_times.find_by(wday: day.wday).end_time
    end
  end

  def start_time_today
    start_time.in_time_zone(office.time_zone)
  end

  def end_time_today
    end_time.in_time_zone(office.time_zone)
  end

  def start_time_on_day(day)
    ActiveSupport::TimeZone[office.time_zone].parse(day.to_s + ' ' + start_time(day))
  end

  def end_time_on_day(day)
    ActiveSupport::TimeZone[office.time_zone].parse(day.to_s + ' '  + end_time(day))
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

  def students_all_locations
    Student.joins(:courses).where(courses: {start_date: start_date, end_date: end_date})
  end

  def students_all_locations_including_attendance_correction_account
    Student.where(id: students_all_locations.select(:id)).or(Student.where(name: '* ATTENDANCE CORRECTION *'))
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

  def self.move_submissions(student:, source_course:, destination_course:)
    source_course.code_reviews.each do |source_cr|
      submission = source_cr.submission_for(student)
      destination_cr = destination_course.code_reviews.find_by(title: source_cr.title)
      if submission && destination_cr
        submission.update_columns(code_review_id: destination_cr.id)
      end
    end
  end

private

  def build_course
    course_params = Github.get_layout_params(layout_file_path)
    self.parttime = course_params['part_time']
    self.internship_course = course_params['internship']
    set_class_times(class_times: course_params['class_times'])
    set_class_days(number_of_weeks: course_params['number_of_weeks'], days_of_week: course_params['class_times'].keys)
    set_description
  end

  def set_class_days(number_of_weeks:, days_of_week:)
    number_of_days = number_of_weeks * days_of_week.count
    class_days = []
    day = start_date
    number_of_days.times do
      until days_of_week.include?(day.strftime('%A')) && !holiday_week?(day)
        if holiday_week?(day)
          day = day.next_week
        else
          day = day.next
        end
      end
      class_days << day unless Rails.configuration.holidays.include?(day.strftime('%Y-%m-%d'))
      day = day.next
    end
    self.class_days = class_days.sort
    set_start_and_end_dates
  end

  def set_start_and_end_dates
    self.start_date = class_days.sort.first
    self.end_date = class_days.sort.last
  end

  def set_description
    self.description = "#{start_date.try('strftime', '%Y-%m')} #{language.try(:name)}"
  end

  def set_class_times(class_times:)
    class_times.each do |class_time|
      wday = Date::DAYNAMES.index(class_time.first)
      the_start_time, the_end_time = class_time.last.split('-')
      self.class_times << ClassTime.find_or_create_by(wday: wday, start_time: the_start_time, end_time: the_end_time)
    end
  end

  def build_code_reviews
    code_review_params = Github.get_layout_params(layout_file_path)['code_reviews']
    if code_review_params.try(:any?)
      order_number = 0
      visible_day_of_week, visible_time, due_days_later, due_time, submissions_not_required, always_visible = code_review_params['settings'].values_at 'visible_day_of_week', 'visible_time', 'due_days_later', 'due_time', 'submissions_not_required', 'always_visible'
      code_review_params['details'].each do |params|
        unless code_reviews.where(title: params['title']).any?
          if params['always_visible'] || always_visible
            visible_datetime, due_datetime = nil
          else
            visible_date = date_of_weekday_on_class_week(class_week: params['visible_class_week'], day_of_week: params['visible_day_of_week'] || visible_day_of_week)
            visible_datetime = time_on_date(date: visible_date, time: params['visible_time'] || visible_time)
            due_date = visible_date + (params['due_days_later'] || due_days_later).days
            due_datetime = time_on_date(date: due_date, time: params['due_time'] || due_time)
          end
          order_number += 1
          cr = code_reviews.new(title: params['title'], github_path: params['filename'], submissions_not_required: params['submissions_not_required'] || submissions_not_required, visible_date: visible_datetime, due_date: due_datetime, journal: params['journal'], number: order_number)
          cr.objectives = params['objectives'].map.with_index(1) {|obj, i| Objective.new(content: obj, number: i)} if params['objectives']
        end
      end
    end
  end

  def holiday_week?(day)
    Rails.configuration.holiday_weeks.include?(day.strftime('%Y-%m-%d'))
  end

  def reassign_admin_current_courses
    Admin.where(current_course_id: self.id).update_all(current_course_id: Course.last.id)
  end

  def update_cohort_end_date(cohort)
    cohort.update(end_date: end_date) if cohort.end_date.nil? || self.end_date > cohort.end_date
  end

  def date_of_weekday_on_class_week(class_week:, day_of_week:)
    class_days_in_week(class_week).last.beginning_of_week(:sunday) + Date::DAYNAMES.index(day_of_week.humanize)
  end

  def class_days_in_week(class_week)
    class_days.sort.group_by { |day| day - day.wday }.values[class_week - 1]
  end

  def time_on_date(date:, time:)
    hour,min = time.split(':')
    date.in_time_zone(office.time_zone).change(hour: hour, min: min)
  end
end
