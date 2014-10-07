class AttendanceRecord < ActiveRecord::Base
  scope :today, -> { where('DATE(created_at) = ?', Date.today) }
  validates :user_id, presence: true, uniqueness: { conditions: -> { where('DATE(created_at) = ?', Date.today) } }

  belongs_to :user

end
