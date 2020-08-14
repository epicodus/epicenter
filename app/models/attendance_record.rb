class AttendanceRecord < ApplicationRecord
  attr_accessor :signing_out
  scope :today, -> { where(date: Time.zone.now.to_date) }

  validates :student_id, presence: true, uniqueness: { scope: :date }
  validates :date, presence: true
  validate :course_in_session?

  before_validation :set_date
  before_validation :sign_in
  before_update :sign_out, if: :signing_out

  belongs_to :student
  belongs_to :pair, class_name: 'Student', optional: true

  def self.todays_totals_for(course, status)
    student_ids = course.students(&:id)
    attributes = { tardy: { student_id: student_ids, tardy: true },
                   left_early: { student_id: student_ids, left_early: true },
                   on_time: { student_id: student_ids, tardy: false, left_early: false }
                 }[status]
    results = today.where(attributes)
    if status == :absent
      course.students.count - today.where(student_id: student_ids).count
    else
      results.count
    end
  end

  def status
    if tardy && left_early
      "Tardy and Left early"
    elsif tardy
      "Tardy"
    elsif left_early
      "Left early"
    else
      "On time"
    end
  end

private

  def course_in_session?
    errors.add(:attendance_record, "sign in not required.") unless student.is_class_day?(date)
  end

  def sign_in
    current_time = Time.zone.now.in_time_zone(student.course.office.time_zone)
    if self.tardy.nil?
      if current_time.sunday?
        class_late_time = "9:00 AM".in_time_zone(student.course.office.time_zone) + 15.minutes
      else
        class_late_time = student.course.start_time.in_time_zone(student.course.office.time_zone) + 15.minutes
      end
      self.tardy = current_time >= class_late_time
      self.left_early = true
    end
  end

  def sign_out
    current_time = Time.zone.now.in_time_zone(student.course.office.time_zone)
    if current_time.sunday?
      class_end_time = "3:00 PM".in_time_zone(student.course.office.time_zone)
    else
      class_end_time = student.course.end_time.in_time_zone(student.course.office.time_zone)
    end
    self.left_early = current_time < (class_end_time - 15.minutes) || current_time > (class_end_time + 15.minutes)
    self.signed_out_time = current_time
  end

  def set_date
    self.date = Time.zone.now.to_date if self.date.nil?
  end
end
