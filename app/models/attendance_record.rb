class AttendanceRecord < ActiveRecord::Base
  scope :today, -> { where(date: Date.today) }
  validates :student_id, presence: true, uniqueness: { scope: :date }
  validates :date, presence: true

  before_validation :set_date_and_tardiness
  before_update :check_left_early
  belongs_to :student

private

  def sign_in
    if self.tardy.nil?
      class_late_time = Time.zone.parse(ENV['CLASS_START_TIME'] ||= '9:05 AM')
      current_time = Time.zone.now
      self.tardy = current_time >= class_late_time
      self.left_early = true
    end
  end

  def check_left_early
    class_end_time = Time.zone.parse(ENV['CLASS_END_TIME'] ||= '4:30 PM')
    current_time = Time.zone.now
    if current_time >= class_end_time
      self.left_early = false
    end
    self.signed_out_time = current_time
  end

  def set_date
    self.date = Date.today if self.date.nil?
  end

  def set_date_and_tardiness
    sign_in
    set_date
  end
end
