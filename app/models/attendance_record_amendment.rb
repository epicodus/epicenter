class AttendanceRecordAmendment
  include ActiveModel::Model

  attr_reader :student_id, :date, :status

  def initialize(attributes={})
    @student_id = attributes[:student_id]
    @date = attributes[:date]
    @status = attributes[:status]
  end

  def save
    if @status == "Absent"
      destroy_attendance_record
    else
      attendance_record = AttendanceRecord.find_or_initialize_by(student_id: @student_id, date: @date)
      attendance_record.tardy = @status == "On time" ? false : true
      attendance_record.save
    end
  end

  def destroy_attendance_record
    attendance_record = AttendanceRecord.find_by(student_id: @student_id, date: @date)
    attendance_record.destroy unless attendance_record.nil?
  end
end
