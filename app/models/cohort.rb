class Cohort < ActiveRecord::Base
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  has_many :users

  def number_of_days_since_start
    last_date = Date.today < end_date ? Date.today : end_date
    (start_date..last_date).select do |date|
      !date.saturday? && !date.sunday?
    end.count
  end
end
