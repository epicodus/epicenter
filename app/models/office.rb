class Office < ApplicationRecord
  validates :name, presence: true
  validates :time_zone, presence: true

  has_many :courses
  has_many :cohorts
  has_many :students
end
