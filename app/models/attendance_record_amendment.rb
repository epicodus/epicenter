class AttendanceRecordAmendment
  include ActiveModel::Model

  validates :student_id, :date, :status, presence: true

  attr_accessor :student_id, :date, :status, :pair_ids

  def initialize(attributes={})
    @student_id = attributes[:student_id]
    @date = attributes[:date] unless attributes[:date].blank?
    @status = attributes[:status]
    @pair_ids = attributes[:pair_ids]
  end

  def save
    if valid?
      amend_attendance_record
    else
      false
    end
  end

private

  def amend_attendance_record
    case status
    when "Absent"
      attendance_record.try(:destroy)
      true
    when "On time"
      attendance_record.update(tardy: false, left_early: false, pair_ids: pair_ids)
    when "Tardy"
      attendance_record.update(tardy: true, left_early: false, pair_ids: pair_ids)
    when "Left early"
      attendance_record.update(left_early: true, tardy: false, pair_ids: pair_ids)
    when "Tardy and Left early"
      attendance_record.update(tardy: true, left_early: true, pair_ids: pair_ids)
    end
  end

  def attendance_record
    @attendance_record ||= AttendanceRecord.find_or_initialize_by(student_id: student_id, date: date)
    @attendance_record.tardy = false # so don't trigger attendance_record#sign_in (will get overridden)
    @attendance_record
  end
end
