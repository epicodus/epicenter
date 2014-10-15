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
      5.times { FactoryGirl.create(:user, cohort: cohort) }
      travel_to cohort.start_date.to_time do
        cohort.users.each { |user| FactoryGirl.create(:attendance_record, user: user) }
        travel 1.day
        cohort.users.first(3).each { |user| FactoryGirl.create(:attendance_record, user: user) }
        cohort_attendance_statistics = CohortAttendanceStatistics.new(cohort)
        expect(cohort_attendance_statistics.daily_presence).to eq({
          cohort.start_date         => 5,
          cohort.start_date + 1.day => 3
        })
      end
    end
  end

  describe '#student_breakdown' do
    include ActiveSupport::Testing::TimeHelpers

    let(:cohort) { FactoryGirl.create(:cohort_starting_january_fifth) }
    let(:cohort_attendance_statistics) { CohortAttendanceStatistics.new(cohort) }
    let!(:first_student) { FactoryGirl.create(:user, name: 'Amo', cohort: cohort) }
    let!(:second_student) { FactoryGirl.create(:user, name: 'Catherine', cohort: cohort) }

    it 'returns data for on time students' do
      travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 8, 55, 00) do
        cohort.users.each { |user| FactoryGirl.create(:attendance_record, user: user) }
        on_time_data = cohort_attendance_statistics.student_breakdown[0]
        expect(on_time_data[:name]).to eq 'On time'
        expect(on_time_data[:data]).to eq [{ second_student.name => 1 }, { first_student.name => 1 }]
      end
    end

    it 'returns data for tardy students' do
      travel_to Time.new(cohort.start_date.year, cohort.start_date.month, cohort.start_date.day, 9, 10, 00) do
        cohort.users.each { |user| FactoryGirl.create(:attendance_record, user: user) }
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
        FactoryGirl.create(:attendance_record, user: second_student)
        absent_data = cohort_attendance_statistics.student_breakdown[2]
        expect(absent_data[:data]).to eq [[first_student.name, 2], [second_student.name, 1]]
      end
    end
  end
end
