feature 'requesting a meeting' do
  context 'visiting as a student' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:course) { FactoryBot.create(:course, admin: admin) }
    let(:student) { FactoryBot.create(:student, course: course) }
    before do
      login_as(student, scope: :student)
      visit new_course_meeting_path(course)
    end

    it 'shows page to request a meeting' do
      expect(page).to have_content("I'd like to request a meeting with a teacher this week.")
    end

    it 'sends email when explanation >= 50 characters', :js do
      allow(EmailJob).to receive(:perform_later).and_return({})
      find('#teacher-meeting').set true
      fill_in 'teacher-meeting-explanation', with: '12345678901234567890123456789012345678901234567890'
      click_on 'Submit'
      expect(EmailJob).to have_received(:perform_later).with(
        { :from => ENV['FROM_EMAIL_REVIEW'],
          :to => student.course.admin.email,
          :subject => "Meeting request for: #{student.name}",
          :text => "12345678901234567890123456789012345678901234567890" }
      )
      expect(page).to have_content("Attendance")
    end

    it 'does not send email if explanation < 50 characters', :js do
      find('#teacher-meeting').set true
      fill_in 'teacher-meeting-explanation', with: 'short explanation'
      click_on 'Submit'
      wait = Selenium::WebDriver::Wait.new ignore: Selenium::WebDriver::Error::NoSuchAlertError
      alert = wait.until { page.driver.browser.switch_to.alert }
      alert.accept
      expect(page).to_not have_content("Attendance")
    end

    it 'does not send email when not requested' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      expect(EmailJob).to_not receive(:perform_later)
      click_on 'No thanks'
      expect(page).to have_content("Attendance")
    end
  end

  context 'visiting as a company' do
    it 'is not authorized' do
      course = FactoryBot.create(:course)
      company = FactoryBot.create(:company)
      login_as(company, scope: :company)
      visit new_course_meeting_path(course)
      expect(page).to have_content("not authorized")
    end
  end
end
