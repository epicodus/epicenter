class AttendanceRecord < ActiveRecord::Base
  attr_accessor :signing_out
  scope :today, -> { where(date: Date.today) }
  validates :student_id, presence: true, uniqueness: { scope: :date }
  validates :date, presence: true

  before_validation :set_date_and_tardiness
  before_update :sign_out, if: :signing_out
  belongs_to :student

private

  def sign_out
    class_end_time = Time.zone.parse(ENV['CLASS_END_TIME'] ||= '4:30 PM')
    current_time = Time.zone.now
    self.left_early = current_time < class_end_time
    self.signed_out_time = current_time
  end

  def sign_in
    if self.tardy.nil?
      class_late_time = Time.zone.parse(ENV['CLASS_START_TIME'] ||= '9:05 AM')
      current_time = Time.zone.now
      self.tardy = current_time >= class_late_time
      self.left_early = true
    end
  end

  def set_date
    self.date = Date.today if self.date.nil?
  end

  def set_date_and_tardiness
    sign_in
    set_date
  end
end
