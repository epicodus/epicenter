class AttendanceRecord < ActiveRecord::Base
  scope :today, -> { where('DATE(created_at) = ?', Date.today) }
  validates :user_id, presence: true
  validate :record_has_not_been_created_today

  belongs_to :user

  def record_has_not_been_created_today
    if user && user.attendance_records.today.exists?
      errors.add(:user_id, 'This user has already signed in today')
    end
  end
end
