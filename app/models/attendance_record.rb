class AttendanceRecord < ActiveRecord::Base
  attr_accessor :signing_out
  scope :today, -> { where(date: Time.zone.now.to_date) }
  validates :student_id, presence: true, uniqueness: { scope: :date }
  validates :date, presence: true
  validates :pair_id, uniqueness: { scope: [:student_id, :date] }
  validate :pair_is_not_self

  before_validation :set_date_and_tardiness
  before_update :sign_out, if: :signing_out
  belongs_to :student

private

  def pair_is_not_self
    if pair_id == student_id
      errors.add(:pair_id, "cannot be yourself.")
      false
    end
  end

  def sign_out
    class_end_time = Time.zone.parse(student.cohort.end_time ||= '4:30 PM')
    current_time = Time.zone.now
    self.left_early = current_time < class_end_time
    self.signed_out_time = current_time
  end

  def sign_in
    if self.tardy.nil?
      class_late_time = Time.zone.parse(student.cohort.start_time ||= '9:05 AM')
      current_time = Time.zone.now
      self.tardy = current_time >= class_late_time
      self.left_early = true
    end
  end

  def set_date
    self.date = Time.zone.now.to_date if self.date.nil?
  end

  def set_date_and_tardiness
    sign_in
    set_date
  end
end
