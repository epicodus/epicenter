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
    let(:start_time) { Time.zone.parse(ENV['CLASS_START_TIME'] ||= '9:05 AM') }

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

  describe '#sign_out' do
    let(:end_time) { Time.zone.parse(ENV['CLASS_END_TIME'] ||= '4:30 PM') }

    it 'is true by default' do
      attendance_record = FactoryGirl.create(:attendance_record)
      expect(attendance_record.left_early).to eq true
    end

    it 'is true when a student leaves early' do
      travel_to end_time - 1.minute do
        shirker_attendance_record = FactoryGirl.create(:attendance_record)
        shirker_attendance_record.sign_out
        shirker_attendance_record.save
        expect(shirker_attendance_record.left_early).to eq true
      end
    end

    it 'is false when a student leaves after the alloted end time' do
      travel_to end_time + 1.minute do
        diligent_attendance_record = FactoryGirl.create(:attendance_record)
        diligent_attendance_record.sign_out
        diligent_attendance_record.save
        expect(diligent_attendance_record.left_early).to eq false
      end
    end

    it 'sets time when a student signs out' do
      attendance_record = FactoryGirl.create(:attendance_record)
      attendance_record.sign_out
      attendance_record.save
      expect(attendance_record.signed_out_time.min).to eq Time.now.min
    end
  end
end
