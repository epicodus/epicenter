class Cohort < ActiveRecord::Base
  validates :description, presence: true
  validates :start_date, presence: true

  default_scope { order(:start_date) }

  has_many :courses, -> { order(:end_date) }
  belongs_to :office
  belongs_to :track

  def self.create_from_course_ids(attributes)
    description = "#{attributes[:start_month]} #{attributes[:track]} #{attributes[:office]}"
    office = Office.find_by(name: attributes[:office])
    track = Track.find_by(description: attributes[:track]) unless attributes[:track] == "ALL"
    course_ids = attributes[:courses]
    courses = course_ids.map { |id| Course.find(id) }.sort_by { |course| course.start_date }
    start_date = courses.first.start_date
    cohort = Cohort.create(description: description, office: office, track: track, start_date: start_date, courses: courses)
    cohort.courses.update_all(track_id: track.id) if track
  end
end
