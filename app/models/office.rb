class Office < ActiveRecord::Base
  validates :name, presence: true
  validates :time_zone, presence: true

  has_many :courses
  has_many :cohorts
end
