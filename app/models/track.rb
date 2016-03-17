class Track < ActiveRecord::Base
  has_many :internship_tracks
  has_many :internships, through: :internship_tracks
end
