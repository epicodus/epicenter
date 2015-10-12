describe StudentAttendanceStatistics do
  let(:course) { FactoryGirl.create(:course) }
  let(:student) { FactoryGirl.create(:student, course: course) }

  describe '#punctuality_hash' do
    it 'returns a breakdown of how many days a student has been present, absent, has left early, and tardy' do
      day_one_before_class_start_time = course.start_date
      day_two_after_class_start_time = course.start_date + 1.day + 10.hours
      day_four = course.start_date + 3.days

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
        expect(data).to eq({ 'On time' => 0, 'Left early' => 3, 'Tardy' => 1, 'Absent' => 1 })
      end
    end
  end

  describe '#days_remaining' do
    it 'returns the number of days remaining in the course' do
      course = FactoryGirl.create(:course)
      student = FactoryGirl.create(:student, course: course)

      travel_to course.start_date + 1.day do
        days_remaining = course.number_of_days_left
        student_attendance_stats = StudentAttendanceStatistics.new(student)
        expect(student_attendance_stats.days_remaining).to eq days_remaining
      end
    end
  end

  describe '#tardies' do
    it 'returns a collection of day objects for student tardies' do
      day_one_tardy = course.start_date.beginning_of_day + 10.hours
      day_two_tardy = day_one_tardy + 1.day
      travel_to day_one_tardy do
        FactoryGirl.create(:attendance_record, student: student)
      end
      travel_to day_two_tardy do
        FactoryGirl.create(:attendance_record, student: student)
      end
      student_attendance_statistics = StudentAttendanceStatistics.new(student)
      expect(student_attendance_statistics.tardies).to match_array [day_one_tardy.to_date, day_two_tardy.to_date]
    end
  end

  describe '#left_earlies' do
    it 'returns a collection of day objects for student leaving class early' do
      day_one = course.start_date.beginning_of_day
      day_two = day_one + 1.day
      day_three = day_two + 1.day
      travel_to day_one do
        attendance_record = FactoryGirl.create(:attendance_record, student: student)
        travel 7.hours do
          attendance_record.update({:signing_out => true})
          student_attendance_statistics = StudentAttendanceStatistics.new(student)
          expect(student_attendance_statistics.left_earlies).to eq [day_one.to_date]
        end
      end
    end
  end

  describe '#absences' do
    it 'returns a collection of day objects for student absences' do
      day_one = course.start_date
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
