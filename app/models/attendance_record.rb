class AttendanceRecord < ActiveRecord::Base
  scope :today, -> { where(created_at: (Time.now.utc.beginning_of_day..Time.now.utc.end_of_day)) }
  validates :user_id, presence: true, uniqueness: { conditions: -> { today } }

  after_validation :set_tardiness

  belongs_to :user

private

  def set_tardiness
    class_late_time = Time.parse(ENV['CLASS_START_TIME'] ||= '9:05 AM')
    current_time = Time.now
    self.tardy = current_time >= class_late_time
  end
end
