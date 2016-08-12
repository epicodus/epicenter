describe AttendanceRecord do
  it { should belong_to :student }
  # it { should validate_presence_of :student_id } # exception is raised before reaching validation of student_id

  describe "validates uniqueness of pair_id to student_id and day" do
    it do
      FactoryGirl.create(:attendance_record)
      FactoryGirl.create(:student)
      should validate_uniqueness_of(:pair_id).scoped_to([:student_id, :date])
    end
  end

  context 'before create' do
    it 'sets the date property to the current date' do
      attendance_record = FactoryGirl.create(:attendance_record)
      expect(attendance_record.date).to eq(Time.zone.now.to_date)
    end
  end

  describe 'adds station to student record if entered' do
    let(:first_user) { FactoryGirl.create(:student) }
    let(:second_user) { FactoryGirl.create(:student) }
    let(:first_attendance_record) { FactoryGirl.create(:attendance_record, student: first_user) }
    let(:second_attendance_record) { FactoryGirl.create(:attendance_record, student: second_user) }

    it 'adds station if entered on pair signin' do
      first_attendance_record.station = "1A"
      second_attendance_record.station = "1A"
      expect(first_attendance_record.station).to eq "1A"
      expect(second_attendance_record.station).to eq "1A"
    end

    it 'allows login even if no station entered' do
      expect(first_attendance_record.valid?).to eq true
      expect(second_attendance_record.valid?).to eq true
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
      FactoryGirl.create(:attendance_record, student: first_user)
      second_attendance_record = FactoryGirl.build(:attendance_record, student: second_user)
      expect(second_attendance_record.valid?).to eq true
    end
  end

  describe '.today' do
    it 'returns all the attendance records for today' do
      FactoryGirl.create(:attendance_record)
      travel_to Time.now + 1.day do
        current_attendance_record = FactoryGirl.create(:attendance_record)
        expect(AttendanceRecord.today).to eq [current_attendance_record]
      end
    end
  end

  describe '#todays_totals_for' do
    let(:course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, course: course) }
    let!(:student_2) { FactoryGirl.create(:student, course: course) }

    it 'returns number of on time attendance records for today for a particular course' do
      FactoryGirl.create(:on_time_attendance_record, student: student)
      FactoryGirl.create(:on_time_attendance_record, student: student_2)
      expect(AttendanceRecord.todays_totals_for(course, :on_time)).to eq 2
    end

    it 'returns number of tardy attendance records for today for a particular course' do
      FactoryGirl.create(:on_time_attendance_record, student: student)
      FactoryGirl.create(:tardy_attendance_record, student: student_2)
      expect(AttendanceRecord.todays_totals_for(course, :tardy)).to eq 1
    end

    it 'returns number of left early attendance records for today for a particular course' do
      FactoryGirl.create(:left_early_attendance_record, student: student)
      FactoryGirl.create(:tardy_attendance_record, student: student_2)
      expect(AttendanceRecord.todays_totals_for(course, :left_early)).to eq 1
    end

    it 'returns number of absences for today for a particular course' do
      FactoryGirl.create(:on_time_attendance_record, student: student)
      expect(AttendanceRecord.todays_totals_for(course, :absent)).to eq 1
    end
  end

  describe '#tardy' do
    let(:student) { FactoryGirl.create(:student) }
    let(:start_time) { student.course.start_time.in_time_zone(student.course.office.time_zone) }
    let(:part_time_student) { FactoryGirl.create(:part_time_student) }
    let(:part_time_start_time) { part_time_student.course.start_time.in_time_zone(part_time_student.course.office.time_zone) }

    it 'is true if the student checks in after the start of class' do
      travel_to start_time + 30.minute do
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

    it 'is true if the part-time student checks in after the start of class' do
      travel_to part_time_start_time + 30.minute do
        tardy_attendance_record = FactoryGirl.create(:attendance_record, student: part_time_student)
        expect(tardy_attendance_record.tardy).to eq true
      end
    end

    it 'is false if the part-time student checks in before the start of class' do
      travel_to part_time_start_time - 1.minute do
        on_time_attendance_record = FactoryGirl.create(:attendance_record, student: part_time_student)
        expect(on_time_attendance_record.tardy).to eq false
      end
    end
  end

  describe '#left_early' do
    let(:student) { FactoryGirl.create(:student) }
    let(:end_time) { student.course.end_time.in_time_zone(student.course.office.time_zone) }
    let(:part_time_student) { FactoryGirl.create(:part_time_student) }
    let(:part_time_end_time) { part_time_student.course.end_time.in_time_zone(part_time_student.course.office.time_zone) }

    it 'is true by default' do
      attendance_record = FactoryGirl.create(:attendance_record)
      expect(attendance_record.left_early).to eq true
    end

    it 'is true when a student leaves early' do
      travel_to end_time - 21.minute do
        shirker_attendance_record = FactoryGirl.create(:attendance_record)
        shirker_attendance_record.update({:signing_out => true})
        expect(shirker_attendance_record.left_early).to eq true
      end
    end

    it 'is false when a student leaves after the alloted end time' do
      travel_to end_time + 1.minute do
        diligent_attendance_record = FactoryGirl.create(:attendance_record)
        diligent_attendance_record.update({:signing_out => true})
        expect(diligent_attendance_record.left_early).to eq false
      end
    end

    it 'is true when a part-time student leaves early' do
      travel_to part_time_end_time - 21.minute do
        shirker_attendance_record = FactoryGirl.create(:attendance_record, student: part_time_student)
        shirker_attendance_record.update({:signing_out => true})
        expect(shirker_attendance_record.left_early).to eq true
      end
    end

    it 'is false when a part-time student leaves after the alloted end time' do
      travel_to part_time_end_time + 1.minute do
        diligent_attendance_record = FactoryGirl.create(:attendance_record, student: part_time_student)
        diligent_attendance_record.update({:signing_out => true})
        expect(diligent_attendance_record.left_early).to eq false
      end
    end
  end

  describe '#sign_out' do
    it 'sets time when a student signs out' do
      attendance_record = FactoryGirl.create(:attendance_record)
      attendance_record.update({:signing_out => true})
      expect(attendance_record.signed_out_time.min).to eq Time.now.min
    end
  end
end
