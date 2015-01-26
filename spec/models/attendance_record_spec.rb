describe AttendanceRecord do
  it { should belong_to :student }
  it { should validate_presence_of :student_id }

  context 'before create' do
    it 'sets the date property to the current date' do
      attendance_record = FactoryGirl.create(:attendance_record)
      expect(attendance_record.date).to eq(Date.today)
    end
  end

  describe 'uniqueness validation for users' do
    it 'validates that an attendance record for a student has not already been created for today' do
      first_attendance_record = FactoryGirl.create(:attendance_record)
      second_attendance_record = FactoryGirl.build(:attendance_record, student: first_attendance_record.student)
      expect(second_attendance_record.valid?).to eq false
    end

    it 'allows multiple users to check in on a single day' do
      first_user = FactoryGirl.create(:student)
      second_user = FactoryGirl.create(:student)
      first_attendance_record = FactoryGirl.create(:attendance_record, student: first_user)
      second_attendance_record = FactoryGirl.build(:attendance_record, student: second_user)
      expect(second_attendance_record.valid?).to eq true
    end
  end

  describe '.today' do
    it 'returns all the attendance records for today' do
      past_attendance_record = FactoryGirl.create(:attendance_record)
      travel_to Time.now + 1.day do
        current_attendance_record = FactoryGirl.create(:attendance_record)
        expect(AttendanceRecord.today).to eq [current_attendance_record]
      end
    end
  end

  describe '#tardy' do
    let(:start_time) { Time.parse(ENV['CLASS_START_TIME']) }

    it 'is true if the student checks in after the start of class' do
      travel_to start_time + 1.minute do
        tardy_attendance_record = FactoryGirl.create(:attendance_record)
        expect(tardy_attendance_record.tardy).to eq true
      end
    end

    it 'is false if the student checks in before the start of class' do
      travel_to start_time - 1.minute do
        on_time_attendance_record = FactoryGirl.create(:attendance_record)
        expect(on_time_attendance_record.tardy).to eq false
      end
    end
  end
end
