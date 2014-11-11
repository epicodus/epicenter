class Cohort < ActiveRecord::Base
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  has_many :students
  has_many :attendance_records, through: :students

  def number_of_days_since_start
    last_date = Date.today <= end_date ? Date.today : end_date
    (start_date..last_date).select do |date|
      !date.saturday? && !date.sunday?
    end.count
  end

  def total_class_days
    (start_date..end_date).select { |date| !date.saturday? && !date.sunday? }.count
  end

  def number_of_days_left
    total_class_days - number_of_days_since_start
  end

  def progress_percent
    (number_of_days_since_start.to_f / total_class_days.to_f) * 100
  end

  def self.current
    where('start_date <= :today AND end_date >= :today', { today: Date.today }).first
  end
end
