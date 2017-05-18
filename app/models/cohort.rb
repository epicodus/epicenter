class Cohort < ActiveRecord::Base
  validates :description, presence: true
  validates :start_date, presence: true

  default_scope { order(:start_date) }

  has_many :courses
  belongs_to :office
end
