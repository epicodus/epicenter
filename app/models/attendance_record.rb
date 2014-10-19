class AttendanceRecord < ActiveRecord::Base
  @@today_in_utc = Time.now.utc.to_date
  
  scope :today, -> { where('DATE(created_at) = ?', @@today_in_utc) }
  validates :user_id, presence: true, uniqueness: { conditions: -> { where('DATE(created_at) = ?', @@today_in_utc) } }

  after_validation :set_tardiness

  belongs_to :user

  private

  def set_tardiness
    class_late_time = Time.parse(ENV['CLASS_START_TIME'])
    current_time = Time.now
    self.tardy = current_time >= class_late_time
  end
end
