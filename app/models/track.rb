class Track < ApplicationRecord
  has_and_belongs_to_many :languages
  has_many :courses, -> { order(:end_date) }
  has_many :cohorts

  default_scope { order(:description) }
  scope :active, -> { where(archived: nil) }

  def self.fulltime
    where('description != ?', 'Part-Time Intro to Programming')
  end
end
