require 'rails_helper'

describe CohortAttendanceStatistics do
  it 'initializes with a cohort' do
    cohort = FactoryGirl.create(:cohort)
    cohort_attendance_statistics = CohortAttendanceStatistics.new(cohort)
    expect(cohort_attendance_statistics.cohort).to eq cohort
  end

  describe '#daily_presence' do
    include ActiveSupport::Testing::TimeHelpers

    it 'returns data for the line chart' do
      cohort = FactoryGirl.create(:cohort)
      2.times { FactoryGirl.create(:student, cohort: cohort) }

      day_one = cohort.start_date
      day_two = cohort.start_date + 1.day

      travel_to day_one do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
      end

      travel_to day_two do
        FactoryGirl.create(:attendance_record, student: cohort.students.first)
      end

      cohort_attendance_statistics = CohortAttendanceStatistics.new(cohort)
      expect(cohort_attendance_statistics.daily_presence).to eq({
        day_one => 2,
        day_two => 1
      })
    end
  end

  describe '#student_breakdown' do
    include ActiveSupport::Testing::TimeHelpers

    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:cohort_attendance_statistics) { CohortAttendanceStatistics.new(cohort) }
    let!(:first_student) { FactoryGirl.create(:student, name: 'Amo', cohort: cohort) }
    let!(:second_student) { FactoryGirl.create(:student, name: 'Catherine', cohort: cohort) }

    it 'returns data for on time students' do
      travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 8, 55, 00) do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        on_time_data = cohort_attendance_statistics.student_breakdown[0]
        expect(on_time_data[:name]).to eq 'On time'
        expect(on_time_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'returns data for tardy students' do
      travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 9, 10, 00) do
        cohort.students.each { |student| FactoryGirl.create(:attendance_record, student: student) }
        tardy_data = cohort_attendance_statistics.student_breakdown[1]
        expect(tardy_data[:name]).to eq 'Tardy'
        expect(tardy_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'returns data for absent students' do
      travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 8, 55, 00) do
        absent_data = cohort_attendance_statistics.student_breakdown[2]
        expect(absent_data[:name]).to eq 'Absent'
        expect(absent_data[:data]).to eq [[second_student.name, 1], [first_student.name, 1]]
      end
    end

    it 'orders data by number of absences descending' do
      travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 8, 55, 00) do
        travel 1.day
        FactoryGirl.create(:attendance_record, student: second_student)
        absent_data = cohort_attendance_statistics.student_breakdown[2]
        expect(absent_data[:data]).to eq [[first_student.name, 2], [second_student.name, 1]]
      end
    end
  end
end
