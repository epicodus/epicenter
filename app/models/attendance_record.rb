class AttendanceRecord < ActiveRecord::Base
  scope :today, -> { where(date: Date.today) }
  validates :student_id, presence: true, uniqueness: { scope: :date }
  validates :date, presence: true

  before_validation :set_date_and_tardiness
  belongs_to :student

private

  def set_tardiness
    if self.tardy.blank?
      class_late_time = Time.parse(ENV['CLASS_START_TIME'] ||= '9:05 AM')
      current_time = Time.zone.now
      self.tardy = current_time >= class_late_time
    end
  end

  def set_date
    self.date = Date.today
  end

  def set_date_and_tardiness
    set_tardiness
    set_date
  end
end
