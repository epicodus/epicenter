class Track < ApplicationRecord
  has_many :internship_tracks
  has_many :internships, through: :internship_tracks
  has_and_belongs_to_many :languages
  has_many :courses, -> { order(:end_date) }
  has_many :cohorts

  default_scope { order(:description) }
  scope :active, -> { where(archived: nil) }

  def self.fulltime
    where('description != ?', 'Part-time')
  end
end
