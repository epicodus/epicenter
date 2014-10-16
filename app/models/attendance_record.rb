class AttendanceRecord < ActiveRecord::Base
  scope :today, -> { where('DATE(created_at) = ?', Date.today) }
  validates :user_id, presence: true, uniqueness: { conditions: -> { where('DATE(created_at) = ?', Date.today) } }

  after_validation :set_tardiness

  belongs_to :user

  private

  def set_tardiness
    class_late_time = Time.parse(ENV['CLASS_START_TIME'])
    current_time = Time.now
    self.tardy = current_time >= class_late_time
  end
end
