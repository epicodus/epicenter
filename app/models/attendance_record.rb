class AttendanceRecord < ActiveRecord::Base
  attr_accessor :signing_out
  scope :today, -> { where(date: Time.zone.now.to_date) }
  validates :student_id, presence: true, uniqueness: { scope: :date }
  validates :date, presence: true
  validates :pair_id, uniqueness: { scope: [:student_id, :date] }

  before_validation :set_date
  before_validation :sign_in
  before_update :sign_out, if: :signing_out
  belongs_to :student

private

  def sign_out
    class_end_time = Time.zone.parse(student.course.end_time) - 15.minutes
    current_time = Time.zone.now
    self.left_early = current_time < class_end_time
    self.signed_out_time = current_time
  end

  def sign_in
    if self.tardy.nil?
      class_late_time = Time.zone.parse(student.course.start_time) + 15.minutes
      current_time = Time.zone.now
      self.tardy = current_time >= class_late_time
      self.left_early = true
    end
  end

  def set_date
    self.date = Time.zone.now.to_date if self.date.nil?
  end
end
