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
        attendance_record = FactoryGirl.create(:attendance_record, student: student)
        travel 18.hours do
          attendance_record.update({:signing_out => true})
          attendance_record.save
        end
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

  context 'within attendance alerts section' do
    it 'shows days students have been late' do
      after_class_start_time = student.cohort.start_date.beginning_of_day + 10.hours
      formatted_after_class_start_time = after_class_start_time.strftime("%A, %B %-d")
      travel_to after_class_start_time do
        FactoryGirl.create(:attendance_record, student: student)
      end
      visit attendance_statistics_path
      expect(page).to have_content formatted_after_class_start_time
    end

    it 'shows days students have been absent' do
      first_day_of_class = student.cohort.start_date
      second_day_of_class = first_day_of_class + 1.day
      formatted_absent_day = first_day_of_class.strftime("%A, %B %-d")
      travel_to second_day_of_class do
        FactoryGirl.create(:attendance_record, student: student)
      end
      visit attendance_statistics_path
      expect(page).to have_content formatted_absent_day
    end
  end
end
