describe AttendanceRecordAmendment do
  it { should validate_presence_of :student_id }
  it { should validate_presence_of :date }
  it { should validate_presence_of :status }

  describe '#save' do
    let(:student) { FactoryBot.create(:student) }

    it 'creates a new attendance record for the student if they did not have one for the given date' do
      travel_to student.course.start_date do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'On time')
        attendance_record_amendment.save
        expect(student.attendance_records.first.date).to eq(Time.zone.now.to_date)
      end
    end

    it 'sets tardy to false if the status is "On time"' do
      travel_to student.course.start_date do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'On time')
        attendance_record_amendment.save
        expect(student.attendance_records.first.tardy).to eq(false)
      end
    end

    it 'sets left_early to false if the status is "On time"' do
      travel_to student.course.start_date do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'On time')
        attendance_record_amendment.save
        expect(student.attendance_records.first.left_early).to eq(false)
      end
    end

    it 'sets tardy to true if the status is "Tardy"' do
      travel_to student.course.start_date do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'Tardy')
        attendance_record_amendment.save
        expect(student.attendance_records.first.tardy).to eq(true)
      end
    end

    it 'sets left_early to true if the status is "Left early"' do
      travel_to student.course.start_date do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'Left early')
        attendance_record_amendment.save
        expect(student.attendance_records.first.left_early).to eq(true)
      end
    end

    it 'sets left_early and tardy to true if the status is "Tardy and Left early"' do
      travel_to student.course.start_date do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'Tardy and Left early')
        attendance_record_amendment.save
        expect(student.attendance_records.first.left_early).to eq(true)
        expect(student.attendance_records.first.tardy).to eq(true)
      end
    end

    it 'updates the status if an attendance record alreads exists for the given day' do
      travel_to student.course.start_date do
        FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date, tardy: true)
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'On time')
        attendance_record_amendment.save
        expect(student.attendance_records_for(:tardy)).to eq 0
      end
    end

    it 'destroys an existing attendance record for the given date if the status is "Absent"' do
      travel_to student.course.start_date do
        FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'Absent')
        attendance_record_amendment.save
        expect(student.attendance_records.count).to eq 0
      end
    end

    it 'updates the pair_id to solo' do
      travel_to student.course.start_date do
        FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date, tardy: true)
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'On time', pair_id: nil)
        attendance_record_amendment.save
        expect(AttendanceRecord.last.pair_id).to eq nil
      end
    end

    it 'updates the pair_id to another student' do
      travel_to student.course.start_date do
        pair = FactoryBot.create(:student)
        FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date, tardy: true)
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: Time.zone.now.to_date, status: 'On time', pair_id: pair.id)
        attendance_record_amendment.save
        expect(AttendanceRecord.last.pair_id).to eq pair.id
      end
    end

    it 'creates a new attendance record on valid course day while course not in session' do
      travel_to student.course.end_date + 1.week do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: student.course.start_date, status: 'On time')
        attendance_record_amendment.save
        expect(student.attendance_records.first.date).to eq student.course.start_date
      end
    end

    it 'creates a new attendance record on course other than current course' do
      course = student.course
      future_course = FactoryBot.create(:future_course)
      student.courses << future_course
      travel_to future_course.end_date do
        attendance_record_amendment = AttendanceRecordAmendment.new(student_id: student.id, date: course.start_date, status: 'On time')
        attendance_record_amendment.save
        expect(student.attendance_records.first.date).to eq student.course.start_date
      end
    end
  end
end
