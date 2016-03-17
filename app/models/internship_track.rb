class InternshipTrack < ActiveRecord::Base
  belongs_to :internship
  belongs_to :track

  validates :internship, presence: true
  validates :track, presence: true
end
