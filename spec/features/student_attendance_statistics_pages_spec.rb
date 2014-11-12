feature 'student attendance statistics page' do
  let(:student) { FactoryGirl.create(:student) }
  before { login_as(student, scope: :student) }

  scenario 'student navigates through navbar link' do
    visit root_path
    click_link 'Attendance record'
    expect(page).to have_content ('Your attendance record')
  end

  context 'within the pie graph', js: true do
    scenario 'student has been on time' do
      before_class_start_time = student.cohort.start_date.beginning_of_day
      travel_to before_class_start_time do
        FactoryGirl.create(:attendance_record, student: student)
      end
      visit attendance_statistics_path
      expect(page).to have_content 'On time'
    end

    scenario 'student has been late' do
      after_class_start_time = student.cohort.start_date.beginning_of_day + 10.hours
      travel_to after_class_start_time do
        FactoryGirl.create(:attendance_record, student: student)
      end
      visit attendance_statistics_path
      expect(page).to have_content 'Tardy'
    end

    scenario 'student has been absent' do
      travel_to student.cohort.start_date do
        visit attendance_statistics_path
        expect(page).to have_content 'Absent'
      end
    end
  end
end
