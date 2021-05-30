class Cohort < ApplicationRecord
  validates :start_date, presence: true
  validates :office, presence: true

  default_scope { order(:start_date) }
  scope :parttime_cohorts, -> { joins(:track).where("tracks.description = 'Part-Time Intro to Programming' OR tracks.description = 'Online'") }
  scope :fulltime_cohorts, -> { joins(:track).where("tracks.description != 'Part-Time Intro to Programming' AND tracks.description != 'Online'") }

  has_many :courses, after_add: :update_end_date
  has_many :parttime_cohort_students, class_name: :User, foreign_key: :parttime_cohort_id
  has_many :starting_cohort_students, class_name: :User, foreign_key: :starting_cohort_id
  has_many :ending_cohort_students, class_name: :User, foreign_key: :ending_cohort_id
  has_many :payments
  has_many :students
  belongs_to :office
  belongs_to :track
  belongs_to :admin

  before_save -> { update_end_date(courses.last) if courses.any? }
  after_create :build_courses_from_layout_file, if: :layout_file_path
  after_create :set_description, unless: :description

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

private

  def build_courses_from_layout_file
    course_layout_files = Github.get_layout_params(layout_file_path)['course_layout_files']
    course_layout_files.each_with_index do |course_layout_filename, index|
      next_course_start_date = self.courses.last.try(:end_date).try(:end_of_week) || start_date
      self.courses << Course.create({ track: track, office: office, admin: admin, language: track.languages.find_by(level: index), start_date: next_course_start_date, layout_file_path: course_layout_filename, active: false })
    end
  end

  def update_end_date(course)
    update(end_date: course.end_date) if self.end_date.nil? || course.end_date > self.end_date
  end

  def set_description
    update(description: "#{start_date.to_s} to #{end_date.to_s} #{office.short_name} #{track.description}")
  end
end
