class AttendanceRecordAmendment
  include ActiveModel::Model

  attr_reader :student_id, :date, :status, :attendance_record

  def initialize(attributes={})
    @student_id = attributes[:student_id]
    @date = attributes[:date]
    @status = attributes[:status]
    @attendance_record = fetch_attendance_record
  end

  def amend
    case status
    when "On time"
      attendance_record.update(tardy: false)
    when "Tardy"
      attendance_record.update(tardy: true)
    when "Absent"
      attendance_record.try(:destroy)
    end
  end

private

  def fetch_attendance_record
    AttendanceRecord.find_or_initialize_by(student_id: student_id, date: date)
  end

  def destroy_attendance_record
    attendance_record.try(:destroy)
  end
end
