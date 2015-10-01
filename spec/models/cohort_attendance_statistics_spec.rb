describe CohortAttendanceStatistics do
  it 'initializes with a cohort' do
    cohort = FactoryGirl.create(:cohort)
    cohort_attendance_statistics = CohortAttendanceStatistics.new(cohort.id)
    expect(cohort_attendance_statistics.cohort).to eq cohort
  end

  describe '#daily_presence' do
    it 'returns data for the line chart' do
      cohort = FactoryGirl.create(:cohort)
      2.times { FactoryGirl.create(:student, cohort: cohort) }

      day_one = cohort.start_date
      day_two = cohort.start_date + 1.day

      travel_to day_one - 5 do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
      end

      travel_to day_one do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
      end

      travel_to day_two do
        FactoryGirl.create(:attendance_record, student: cohort.students.first)
      end

      cohort_attendance_statistics = CohortAttendanceStatistics.new(cohort.id)
      expect(cohort_attendance_statistics.daily_presence).to eq({
        day_one => 2,
        day_two => 1
      })
    end
  end

  describe '#student_attendance_data' do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:cohort_attendance_statistics) { CohortAttendanceStatistics.new(cohort.id) }
    let!(:first_student) { FactoryGirl.create(:student, name: 'Amo', cohort: cohort) }
    let!(:second_student) { FactoryGirl.create(:student, name: 'Catherine', cohort: cohort) }

    it 'returns data for on time students' do
      travel_to cohort.start_date do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        travel_to cohort.start_date + 18.hours do
          cohort.students.each do |student|
            student.attendance_records.all.each do |record|
              record.update({:signing_out => true})
            end
          end
        end
        on_time_data = cohort_attendance_statistics.student_attendance_data[0]
        expect(on_time_data[:name]).to eq 'On time'
        expect(on_time_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'returns data for tardy students' do
      start_time = Time.zone.parse(cohort.start_time)

      travel_to start_time + 20.minute do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        tardy_data = cohort_attendance_statistics.student_attendance_data[2]
        expect(tardy_data[:name]).to eq 'Tardy'
        expect(tardy_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'returns data for early leaving students' do
      start_time = Time.zone.parse(cohort.start_time)
      end_time = Time.zone.parse(cohort.end_time)

      travel_to start_time - 1.minute do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        travel 7.hours do
          cohort.students.each { |student| student.attendance_records.today.first.update({:signing_out => true}) }
          left_early_data = cohort_attendance_statistics.student_attendance_data[1]
          expect(left_early_data[:name]).to eq 'Left early'
          expect(left_early_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
        end
      end
    end

    it 'returns data for absent students' do
      travel_to cohort.start_date do
        absent_data = cohort_attendance_statistics.student_attendance_data[3]
        expect(absent_data[:name]).to eq 'Absent'
        expect(absent_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'orders data by number of absences descending' do
      travel_to cohort.start_date + 1.day do
        FactoryGirl.create(:attendance_record, student: second_student)
        absent_data = cohort_attendance_statistics.student_attendance_data[3]
        expect(absent_data[:data]).to eq [[first_student.name, 2], [second_student.name, 1]]
      end
    end
  end
end
