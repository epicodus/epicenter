class AttendanceRecordAmendment
  include ActiveModel::Model

  validates :student_id, :date, :status, presence: true

  attr_accessor :student_id, :date, :status, :pair_id

  def initialize(attributes={})
    @student_id = attributes[:student_id]
    @date = attributes[:date] unless attributes[:date].blank?
    @status = attributes[:status]
    @pair_id = attributes[:pair_id]
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
    when "On time"
      attendance_record.update(tardy: false, left_early: false)
    when "Tardy"
      attendance_record.update(tardy: true, left_early: false)
    when "Left early"
      attendance_record.update(left_early: true, tardy: false)
    when "Absent"
      attendance_record.try(:destroy)
    when "Tardy and Left early"
      attendance_record.update(tardy: true, left_early: true)
    end
    attendance_record.update(pair_id: pair_id) if AttendanceRecord.exists?(attendance_record.id)
  end

  def attendance_record
    @attendance_record ||= AttendanceRecord.find_or_initialize_by(student_id: student_id, date: date)
  end
end
