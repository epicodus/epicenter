describe CourseAttendanceStatistics do
  it 'initializes with a course' do
    course = FactoryGirl.create(:course)
    course_attendance_statistics = CourseAttendanceStatistics.new(course.id)
    expect(course_attendance_statistics.course).to eq course
  end

  describe '#daily_presence' do
    it 'returns data for the line chart' do
      course = FactoryGirl.create(:course)
      2.times { FactoryGirl.create(:student, course: course) }

      day_one = course.start_date
      day_two = course.start_date + 1.day

      travel_to day_one - 5 do
        course.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
      end

      travel_to day_one do
        course.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
      end

      travel_to day_two do
        FactoryGirl.create(:attendance_record, student: course.students.first)
      end

      course_attendance_statistics = CourseAttendanceStatistics.new(course.id)
      expect(course_attendance_statistics.daily_presence).to eq({
        day_one => 2,
        day_two => 1
      })
    end
  end

  describe '#student_attendance_data' do
    let(:course) { FactoryGirl.create(:course) }
    let(:course_attendance_statistics) { CourseAttendanceStatistics.new(course.id) }
    let!(:first_student) { FactoryGirl.create(:student, name: 'Amo', course: course) }
    let!(:second_student) { FactoryGirl.create(:student, name: 'Catherine', course: course) }

    it 'returns data for on time students' do
      travel_to course.start_date do
        course.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        travel_to course.start_date + 18.hours do
          course.students.each do |student|
            student.attendance_records.all.each do |record|
              record.update({:signing_out => true})
            end
          end
        end
        on_time_data = course_attendance_statistics.student_attendance_data[0]
        expect(on_time_data[:name]).to eq 'On time'
        expect(on_time_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'returns data for tardy students' do
      start_time = Time.zone.parse(course.start_time)

      travel_to start_time + 30.minute do
        course.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        tardy_data = course_attendance_statistics.student_attendance_data[2]
        expect(tardy_data[:name]).to eq 'Tardy'
        expect(tardy_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'returns data for early leaving students' do
      start_time = Time.zone.parse(course.start_time)
      end_time = Time.zone.parse(course.end_time)

      travel_to start_time - 1.minute do
        course.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        travel 7.hours do
          course.students.each { |student| student.attendance_records.today.first.update({:signing_out => true}) }
          left_early_data = course_attendance_statistics.student_attendance_data[1]
          expect(left_early_data[:name]).to eq 'Left early'
          expect(left_early_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
        end
      end
    end

    it 'returns data for absent students' do
      travel_to course.start_date do
        absent_data = course_attendance_statistics.student_attendance_data[3]
        expect(absent_data[:name]).to eq 'Absent'
        expect(absent_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'orders data by number of absences descending' do
      travel_to course.start_date + 1.day do
        FactoryGirl.create(:attendance_record, student: second_student)
        absent_data = course_attendance_statistics.student_attendance_data[3]
        expect(absent_data[:data]).to eq [[first_student.name, 2], [second_student.name, 1]]
      end
    end
  end
end
