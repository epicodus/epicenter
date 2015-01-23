class AttendanceRecord < ActiveRecord::Base
  scope :today, -> { where(created_at: (Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)) }
  validates :student_id, presence: true, uniqueness: { conditions: -> { today }, message: 'already signed in' }

  after_validation :set_tardiness

  belongs_to :student

private

  def set_tardiness
    class_late_time = Time.parse(ENV['CLASS_START_TIME'] ||= '9:05 AM')
    current_time = Time.zone.now
    self.tardy = current_time >= class_late_time
  end
end
