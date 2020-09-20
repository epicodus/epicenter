class Cohort < ApplicationRecord
  validates :start_date, presence: true
  validates :office, presence: true

  default_scope { order(:start_date) }
  scope :parttime_cohorts, -> { joins(:track).where("tracks.description = 'Part-Time Intro to Programming' OR tracks.description = 'Online'") }
  scope :fulltime_cohorts, -> { joins(:track).where("tracks.description != 'Part-Time Intro to Programming' AND tracks.description != 'Online'") }

  has_and_belongs_to_many :courses, -> { order(:end_date) }, after_add: :update_end_date
  has_many :parttime_cohort_students, class_name: :User, foreign_key: :parttime_cohort_id
  has_many :starting_cohort_students, class_name: :User, foreign_key: :starting_cohort_id
  has_many :ending_cohort_students, class_name: :User, foreign_key: :ending_cohort_id
  has_many :students
  belongs_to :office
  belongs_to :track
  belongs_to :admin

  after_create :create_courses_from_layout_file, if: ->(cohort) { cohort.courses.empty? }
  after_create :set_description, if: ->(cohort) { cohort.description.blank? }

  attr_accessor :layout_file_path

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

  def self.current_and_future_cohorts
    where('end_date >= ?', Time.zone.now.to_date)
  end

  def create_courses_from_layout_file
    response = Github.get_content(layout_file_path)
    if response[:error]
      errors.add(:base, 'Unable to pull layout file from Github')
      throw(:abort)
    else
      layout_file = response[:content]
      layout_params = YAML.load(layout_file)
      start_time = layout_params[:start_time]
      end_time = layout_params[:end_time]
      layout_params[:course_layout_files].each_with_index do |course_layout_filename, index|
        next_course_start_date = skip_holidays(self.courses.last.try(:end_date).try(:next_week) || start_date)
        if course_layout_filename.include? 'internship'
          self.courses << Course.find_or_create_by({ office: office, language: Language.find_by(level: 4), start_date: next_course_start_date, start_time: start_time, end_time: end_time, layout_file_path: course_layout_filename, active: false })
          internship_course = courses.internship_courses.last
          internship_course.set_description
          internship_course.save
        else
          self.courses << Course.create({ track: track, office: office, admin: admin, language: track.languages.find_by(level: index), start_date: next_course_start_date, start_time: start_time, end_time: end_time, layout_file_path: course_layout_filename })
        end
      end
    end
  end

  def get_nth_week_of_cohort(n)
  nth_week = start_date
    n.times do
      nth_week = skip_holidays(nth_week+1.week).beginning_of_week
    end
  nth_week
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
    update(description: "#{start_date.to_s} to #{end_date.to_s} #{office.short_name} #{track.description}")
  end
end
