describe AttendanceRecordAmendment do
  describe '#amend' do
    let(:student) { FactoryGirl.create(:student) }

    it 'creates a new attendance record for the student if they did not have one for the given date' do
      attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Date.today, status: 'On time')
      attendance_record_amendment.amend
      expect(student.attendance_records.first.date).to eq(Date.today)
    end

    it 'sets tardy to false if the status is "On time"' do
      attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Date.today, status: 'On time')
      attendance_record_amendment.amend
      expect(student.attendance_records.first.tardy).to eq(false)
    end

    it 'sets tardy to true if the status is "Tardy"' do
      attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Date.today, status: 'Tardy')
      attendance_record_amendment.amend
      expect(student.attendance_records.first.tardy).to eq(true)
    end

    it 'updates the status if an attendance record alread exists for the given day' do
      FactoryGirl.create(:attendance_record, student: student, date: Date.today, tardy: true)
      attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Date.today, status: 'On time')
      attendance_record_amendment.amend
      expect(student.tardies).to eq 0
    end

    it 'destroys an existing attendance record for the given date if the status is "Absent"' do
      FactoryGirl.create(:attendance_record, student: student, date: Date.today)
      attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Date.today, status: 'Absent')
      attendance_record_amendment.amend
      expect(student.attendance_records.count).to eq 0
    end
  end
end
