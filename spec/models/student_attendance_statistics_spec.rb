describe StudentAttendanceStatistics do
  let(:cohort) { FactoryGirl.create(:cohort) }
  let(:student) { FactoryGirl.create(:student, cohort: cohort) }

  describe '#punctuality_hash' do
    it 'returns a breakdown of how many days a student has been present, absent, and tardy' do
      day_one_before_class_start_time = cohort.start_date
      day_two_after_class_start_time = cohort.start_date + 1.day + 10.hours
      day_four = cohort.start_date + 3.days

      travel_to day_one_before_class_start_time do
        FactoryGirl.create(:attendance_record, student: student)
      end

      travel_to day_two_after_class_start_time do
        FactoryGirl.create(:attendance_record, student: student)
      end

      travel_to day_four do
        FactoryGirl.create(:attendance_record, student: student)
        student_attendance_statistics = StudentAttendanceStatistics.new(student)
        data = student_attendance_statistics.punctuality_hash
        expect(data).to eq({ 'On time' => 2, 'Tardy' => 1, 'Absent' => 1 })
      end
    end
  end

  describe '#days_remaining' do
    it 'returns the number of days remaining in the cohort' do
      cohort = FactoryGirl.create(:cohort)
      student = FactoryGirl.create(:student, cohort: cohort)

      travel_to cohort.start_date + 1.day do
        days_remaining = cohort.number_of_days_left
        student_attendance_stats = StudentAttendanceStatistics.new(student)
        expect(student_attendance_stats.days_remaining).to eq days_remaining
      end
    end
  end

  describe '#tardies' do
    it 'returns a collection of day objects for student tardies' do
      day_one_tardy = cohort.start_date.beginning_of_day + 10.hours
      day_two_tardy = day_one_tardy + 1.day
      travel_to day_one_tardy do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to day_two_tardy do
        FactoryGirl.create(:attendance_record, student: student)
      end
      student_attendance_statistics = StudentAttendanceStatistics.new(student)
      expect(student_attendance_statistics.tardies).to eq [day_one_tardy.to_date, day_two_tardy.to_date]
    end
  end

  describe '#absences' do
    it 'returns a collection of day objects for student absences' do
      day_one = cohort.start_date
      day_two = day_one + 1.day
      day_three = day_two + 1.day
      travel_to day_three do
        FactoryGirl.create(:attendance_record, student: student)
        student_attendance_statistics = StudentAttendanceStatistics.new(student)
        expect(student_attendance_statistics.absences).to eq [day_one.to_date, day_two.to_date]
      end
    end
  end
end
