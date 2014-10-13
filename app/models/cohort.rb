class Cohort < ActiveRecord::Base
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :description, presence: true
  
  has_many :users
end
