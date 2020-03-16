feature 'Visiting the student course page' do
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'you do not see the daily submission link' do
      visit course_student_path(student.course, student)
      expect(page).to_not have_content 'Your Github repo(s) for the day'
    end

    scenario 'you can view the list of submissions' do
      visit course_daily_submissions_path(student.course)
      expect(page).to have_content 'Daily Submissions for'
    end

    scenario 'you can navigate to list of submissions from course page' do
      visit course_path(student.course)
      click_on 'Daily Submissions'
      expect(page).to have_content 'Daily Submissions for'
    end

    scenario 'you can view submissions for today' do
      student2 = FactoryBot.create(:student, course: student.course)
      DailySubmission.create(student: student, link: 'student 1 submission')
      DailySubmission.create(student: student2, link: 'student 2 submission')
      visit course_daily_submissions_path(student.course)
      expect(page).to have_content 'student 1 submission'
      expect(page).to have_content 'student 2 submission'
    end

    scenario 'you can view submission for another class day' do
      student2 = FactoryBot.create(:student, course: student.course)
      DailySubmission.create(student: student, link: 'today submission')
      travel_to student2.course.start_date do
        DailySubmission.create(student: student2, link: 'course start date submission')
      end
      visit course_daily_submissions_path(student.course)
      expect(page).to have_content 'today submission'
      select student2.course.start_date.strftime("%B %d, %Y, %A"), from: 'date'
      click_on 'Change day'
      expect(page).to have_content "Daily Submissions for #{student2.course.start_date.strftime("%A %B %d, %Y")}"
      expect(page).to have_content 'course start date submission'
    end
  end

  context 'as a student' do
    before { login_as(student, scope: :student) }

    scenario 'you can see the daily submission link' do
      visit course_student_path(student.course, student)
      expect(page).to have_content 'Your Github repo(s) for the day'
    end

    scenario 'you are not authorized to see the list of submissions' do
      visit course_daily_submissions_path(student.course)
      expect(page).to have_content 'You are not authorized'
    end

    scenario 'submits daily submission url' do
      visit course_student_path(student.course, student)
      fill_in 'daily_submission_link', with: 'example.com/foo'
      click_on 'Submit'
      expect(page).to have_content 'Thank you for your daily submission.'
      expect(DailySubmission.first.link).to eq 'example.com/foo'
    end

    scenario 'replaces with second submission by same student on same day' do
      visit course_student_path(student.course, student)
      fill_in 'daily_submission_link', with: 'example.com/foo'
      click_on 'Submit'
      fill_in 'daily_submission_link', with: 'example.com/foo2'
      click_on 'Submit'
      expect(page).to have_content 'Thank you for your daily submission.'
      expect(DailySubmission.first.link).to eq 'example.com/foo2'
    end
  end
end
