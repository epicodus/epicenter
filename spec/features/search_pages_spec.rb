feature 'searching for a student' do
  scenario 'as a guest' do
    visit students_path
    expect(page).to have_content 'You need to sign in.'
  end

  scenario 'as a student' do
    student = FactoryBot.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit students_path
    expect(page).to have_content 'You are not authorized to access this page.'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'when no query is made' do
      visit students_path
      click_on 'student-search'
      expect(page).to have_content 'No students found.'
    end

    scenario 'when a query is made for an archived student' do
      archived_student = FactoryBot.create(:student)
      FactoryBot.create(:attendance_record, student: archived_student)
      archived_student.destroy
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: archived_student.name
        click_on 'student-search'
      end
      expect(page).to have_content archived_student.name
      expect(page).to have_content 'Archived'
    end

    scenario 'when a query is made for an unenrolled student' do
      unenrolled_student = FactoryBot.create(:student)
      Enrollment.find_by(student: unenrolled_student).destroy
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: unenrolled_student.name
        click_on 'student-search'
      end
      expect(page).to have_content unenrolled_student.name
      expect(page).to have_content 'Not enrolled'
    end

    scenario 'when a query is made for a current student' do
      student = FactoryBot.create(:student)
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: student.name
        click_on 'student-search'
      end
      expect(page).to have_content student.name
      expect(page).to have_content 'Current student'
    end

    scenario 'when a query is made for a future student' do
      course = FactoryBot.create(:future_course)
      student = FactoryBot.create(:student, courses: [course])
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: student.name
        click_on 'student-search'
      end
      expect(page).to have_content student.name
      expect(page).to have_content 'Future student'
    end

    scenario 'when a query is made for a student who has graduated' do
      course = FactoryBot.create(:internship_course)
      past_student = FactoryBot.create(:user_with_all_documents_signed, courses: [course])
      visit root_path
      travel_to past_student.course.end_date + 1.days do
        within '#navbar-search' do
          fill_in 'search', with: past_student.name
          click_on 'student-search'
        end
        expect(page).to have_content past_student.name
        expect(page).to have_content 'Graduate'
      end
    end

    scenario 'when a query is made for an existing student with a payment made', :vcr, :stripe_mock, :stub_mailgun do
      in_class_student = FactoryBot.create(:student_with_all_documents_signed_and_credit_card, email: 'example@example.com')
      FactoryBot.create(:payment_with_credit_card, student: in_class_student)
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: in_class_student.name
        click_on 'student-search'
      end
      expect(page).to have_content in_class_student.name
      expect(page).to have_content 'Current student'
    end

    scenario 'when a query is made for a student who withdrew' do
      past_student = FactoryBot.create(:user_with_all_documents_signed)
      visit root_path
      travel_to past_student.course.end_date + 1.days do
        within '#navbar-search' do
          fill_in 'search', with: past_student.name
          click_on 'student-search'
        end
        expect(page).to have_content past_student.name
        expect(page).to have_content 'Incomplete'
      end
    end

    scenario 'when a query is made for a student who finished before 2016' do
      course = FactoryBot.create(:course, class_days: [Time.new(2015, 1, 1).to_date])
      student = FactoryBot.create(:student, courses: [course])
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: student.name
        click_on 'student-search'
      end
      expect(page).to have_content student.name
      expect(page).to have_content 'Pre-2016'
    end

    scenario 'when a query is made for a part-time student' do
      course = FactoryBot.create(:part_time_course, class_days: [Time.zone.now.to_date.monday])
      student = FactoryBot.create(:student, courses: [course])
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: student.name
        click_on 'student-search'
      end
      expect(page).to have_content student.name
      expect(page).to have_content 'Part-time'
    end

    scenario 'when a query is made for a student id' do
      student = FactoryBot.create(:student)
      visit root_path
      within '#navbar-search' do
        fill_in 'search', with: student.id
        click_on 'student-search'
      end
      expect(page).to have_content student.name
    end
  end
end
