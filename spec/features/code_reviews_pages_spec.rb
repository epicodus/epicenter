feature 'viewing the code review index page' do
  let!(:code_review) { FactoryBot.create(:code_review) }

  scenario 'as a guest' do
    visit course_path(code_review.course)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: code_review.course) }
    before { login_as(student, scope: :student) }

    scenario 'redirects the student to the root path' do
      visit course_path(code_review.course)
      expect(page).to have_content 'You are not authorized'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:code_review) { FactoryBot.create(:code_review) }

    before { login_as(admin, scope: :admin) }

    scenario 'has a link to create a new code review' do
      visit course_path(code_review.course)
      click_on 'New'
      expect(page).to have_content 'New code review'
    end

    scenario 'shows the number of submissions needing review for each code_review' do
      FactoryBot.create(:submission, code_review: code_review)
      visit course_path(code_review.course)
      expect(page).to have_content '1 new submission'
    end

    scenario 'admin clicks on number of submission badge and is taken to submissions index of that code_review' do
      FactoryBot.create(:submission, code_review: code_review)
      visit course_path(code_review.course)
      click_link '1 new submission'
      expect(page).to have_content "Submissions for #{code_review.title}"
    end

    scenario 'has a button to save order of code reviews' do
      visit course_path(code_review.course)
      expect(page).to have_button 'Save order'
    end

    scenario 'changes lesson order' do
      FactoryBot.create(:code_review, course: code_review.course)
      visit course_path(code_review.course)
      click_on 'Save order'
      expect(page).to have_content 'Order has been saved'
    end
  end
end

feature 'visiting the code review show page' do
  let(:code_review) { FactoryBot.create(:code_review) }

  scenario 'as a guest' do
    visit course_code_review_path(code_review.course, code_review)
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, courses: [code_review.course]) }
    before do
      login_as(admin, scope: :admin)
      visit course_code_review_path(code_review.course, code_review)
    end

    scenario 'has a link to edit code_review' do
      click_on 'Edit'
      expect(page).to have_content 'Edit code review'
    end

    scenario 'has a link to delete code_review' do
      click_on 'Delete'
      expect(page).to have_content "#{code_review.title} has been deleted"
    end

    scenario 'shows code review content' do
      expect(page).to have_content "test content"
    end

    scenario 'does not show survey if not present' do
      expect(page).to have_content "No survey"
    end

    scenario 'shows survey if present' do
      code_review.survey = 'widget_test.js'
      code_review.save
      visit course_code_review_path(code_review.course, code_review)
      expect(page).to_not have_content "No survey"
    end
  end

  context 'as a student' do
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: code_review.course) }
    before { login_as(student, scope: :student) }
    subject { page }

    context 'before submitting' do
      before do
        visit course_student_path(code_review.course, student)
        click_link 'Submit'
      end

      it { is_expected.to have_button 'Submit' }
      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end

    it 'displays message before code review is visible' do
      travel_to code_review.visible_date - 5.days do
        visit course_code_review_path(code_review.course, code_review)
        expect(page).to have_content "Not yet available."
      end
    end

    it 'displays code review content when code review is visible' do
      travel_to code_review.visible_date + 1.day do
        visit course_code_review_path(code_review.course, code_review)
        expect(page).to have_content "test content"
      end
    end

    it 'displays message after code review completed passing', :stub_mailgun do
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:passing_review, submission: submission)
      visit course_code_review_path(code_review.course, code_review)
      expect(page).to have_content "Completed successfully!"
    end

    it 'does not display code review content section if review has no content' do
      code_review.update(content: nil)
      visit course_code_review_path(code_review.course, code_review)
      expect(page).to_not have_content "<h4><strong>Project</strong></h4>"
    end

    it 'does not display code review content section if review has no date' do
      code_review.visible_date = nil
      code_review.due_date = nil
      code_review.save
      visit course_code_review_path(code_review.course, code_review)
      expect(page).to_not have_content "<h4><strong>Project</strong></h4>"
    end

    scenario 'does not show survey if not present' do
      visit course_code_review_path(code_review.course, code_review)
      expect(page).to_not have_content "survey"
    end

    scenario 'shows survey if present and student has not yet passed expectations' do
      code_review.survey = 'foo.js'
      code_review.save
      visit course_code_review_path(code_review.course, code_review)
      expect(page).to have_content "survey"
    end

    scenario 'does not show survey if student already passed expectations' do
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:passing_review, submission: submission)
      visit course_code_review_path(code_review.course, code_review)
      expect(page).to_not have_content "survey"
    end

    context 'when submitting' do
      before { visit course_code_review_path(code_review.course, code_review) }

      scenario 'with valid input' do
        fill_in 'submission_link', with: 'http://github.com'
        fill_in 'submission-student-note', with: 'student note'
        check 'understand-guidelines'
        click_button 'Submit'
        is_expected.to have_content 'Thank you for submitting'
        is_expected.to have_content "I'd like to request a meeting with a teacher this week."
      end

      scenario 'sets review status to pending on inital submission' do
        fill_in 'submission_link', with: 'http://github.com'
        fill_in 'submission-student-note', with: 'student note'
        check 'understand-guidelines'
        click_button 'Submit'
        expect(student.submissions.last.review_status).to eq "pending"
      end

      scenario 'adds student note' do
        fill_in 'submission_link', with: 'http://github.com'
        fill_in 'submission-student-note', with: 'student note'
        check 'understand-guidelines'
        click_button 'Submit'
        expect(student.submissions.last.submission_notes.last.content).to eq "student note"
      end

      scenario 'with invalid input' do
        check 'understand-guidelines'
        click_button 'Submit'
        is_expected.to have_content "can't be blank"
      end
    end

    context 'when submitting reflection' do
      let(:journal) { FactoryBot.create(:code_review, course: student.course, journal: true) }
      before { visit course_code_review_path(journal.course, journal) }

      it { is_expected.to_not have_content 'Objectives' }
      it { is_expected.to_not have_content 'Submission link' }
      it { is_expected.to_not have_content 'Please let your teacher know' }
      it { is_expected.to_not have_content 'I confirm that I have read and understand' }

      scenario 'with valid input' do
        fill_in 'submission_journal', with: 'test entry'
        click_button 'Submit'
        is_expected.to have_content 'Thank you for submitting your reflection'
        is_expected.to_not have_content "I'd like to request a meeting with a teacher this week."
      end

      scenario 'is automatically marked as passing' do
        fill_in 'submission_journal', with: 'test entry'
        click_button 'Submit'
        expect(student.submissions.last.review_status).to eq "pass"
      end

      scenario 'with invalid input' do
        click_button 'Submit'
        is_expected.to have_content "can't be blank"
      end
    end

    context 'after having submitted' do
      before do
        FactoryBot.create(:submission, code_review: code_review, student: student, times_submitted: 1)
        visit course_code_review_path(code_review.course, code_review)
      end

      it { is_expected.to have_button 'Resubmit' }
      it { is_expected.to have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
      it { is_expected.to have_content 'Submitted 1 time' }
    end

    context 'after having submitted reflection' do
      before do
        journal = FactoryBot.create(:code_review, journal: true)
        FactoryBot.create(:submission, code_review: journal, student: student, journal: 'test entry', times_submitted: 1)
        visit course_code_review_path(code_review.course, code_review)
      end
      it { is_expected.to_not have_content 'Submitted 1 time' }
    end

    context 'after submission has been reviewed', :stub_mailgun do
      let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }
      let!(:review) { FactoryBot.create(:passing_review, submission: submission) }

      before { visit course_code_review_path(code_review.course, code_review) }

      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to have_content review.note }
      it { is_expected.to have_content 'Meets expectations' }
    end

    context 'before resubmitting' do
      let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }

      it 'renders markdown' do
        submission.submission_notes.create(content: '- test student note')
        visit course_code_review_path(code_review.course, code_review)
        expect(page).to have_css('li', text: 'test student note')
      end
    end

    context 'after resubmitting', :stub_mailgun do
      let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }

      before do
        FactoryBot.create(:passing_review, submission: submission)
        visit course_code_review_path(code_review.course, code_review)
      end

      scenario 'successfully' do
        fill_in 'submission-student-note', with: 'resubmission student note'
        click_button 'Resubmit'
        expect(page).to have_content 'Submission updated'
        expect(page).to have_content "I'd like to request a meeting with a teacher this week."
      end

      scenario 'sets review_status to pending on resubmission' do
        fill_in 'submission-student-note', with: 'resubmission student note'
        click_button 'Resubmit'
        expect(student.submissions.last.review_status).to eq "pending"
      end

      scenario 'unsuccessfully' do
        fill_in 'submission_link', with: ''
        click_button 'Resubmit'
        expect(page).to have_content "There was a problem submitting."
      end
    end

    context 'after resubmitting reflection', :stub_mailgun do
      let(:journal) { FactoryBot.create(:code_review, course: student.course, journal: true)}
      let(:submission) { FactoryBot.create(:submission, code_review: journal, student: student, journal: 'test entry', link: nil) }

      before do
        FactoryBot.create(:passing_review, submission: submission)
        visit course_code_review_path(journal.course, journal)
      end

      scenario 'successfully' do
        fill_in 'submission_journal', with: 'test entry updated'
        click_button 'Resubmit'
        expect(page).to have_content 'Reflection updated'
        expect(page).to_not have_content "I'd like to request a meeting with a teacher this week."
      end

      scenario 'is automatically marked as passing again' do
        fill_in 'submission_journal', with: 'test entry updated'
        click_button 'Resubmit'
        expect(submission.review_status).to eq "pass"
      end

      scenario 'unsuccessfully' do
        fill_in 'submission_journal', with: ''
        click_button 'Resubmit'
        expect(page).to have_content "There was a problem submitting."
      end
    end
  end
end

feature 'viewing reflection submission' do
  context 'as an admin' do
    let(:journal) { FactoryBot.create(:code_review, journal: true)}
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: journal.course) }
    let(:admin) { FactoryBot.create(:admin, current_course: journal.course) }
    let(:submission) { FactoryBot.create(:submission, code_review: journal, student: student, journal: 'test entry', link: nil) }

    before { login_as(admin, scope: :admin) }

    scenario 'viewing from review creation page' do
      visit new_submission_review_path(submission)
      expect(page).to have_content 'Reflection submission:'
      expect(page).to have_content 'test entry'
    end
  end
end

feature 'creating a code review' do
  let(:course) { FactoryBot.create(:course) }

  scenario 'as a guest' do
    visit new_course_code_review_path(course)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student' do
    student = FactoryBot.create(:student)
    login_as(student, scope: :student)
    visit new_course_code_review_path(course)
    expect(page).to have_content 'You are not authorized to access this page.'
  end

  context 'as an admin' do
    let(:code_review) { FactoryBot.build(:code_review) }
    let(:admin) { FactoryBot.create(:admin, current_course: code_review.course) }

    before do
      login_as(admin, scope: :admin)
      visit new_course_code_review_path(course)
    end

    scenario 'with valid input' do
      fill_in 'Title', with: code_review.title
      fill_in 'code_review_objectives_attributes_0_content', with: 'objective'
      click_button 'Create Code review'
      expect(page).to have_content 'Code review has been saved'
    end

    scenario 'with invalid input' do
      click_button 'Create Code review'
      expect(page).to have_content "can't be blank"
    end

    scenario 'with dates' do
      fill_in 'Title', with: code_review.title
      fill_in 'code_review_objectives_attributes_0_content', with: 'objective'
      click_button 'Create Code review'
      expect(CodeReview.first.visible_date).to_not eq nil
      expect(CodeReview.first.due_date).to eq CodeReview.first.visible_date + 9.hours
    end

    scenario 'part-time code review with dates' do
      course.update_columns(parttime: true)
      travel_to Date.parse('2021-01-04') do
        visit new_course_code_review_path(course)
        fill_in 'Title', with: code_review.title
        fill_in 'code_review_objectives_attributes_0_content', with: 'objective'
        click_button 'Create Code review'
        expect(CodeReview.first.visible_date).to_not eq nil
        expect(CodeReview.first.due_date).to eq CodeReview.first.visible_date + 1.week
      end
    end

    scenario 'always visible' do
      fill_in 'Title', with: code_review.title
      fill_in 'code_review_objectives_attributes_0_content', with: 'objective'
      find('#always_visible').set true
      click_button 'Create Code review'
      expect(CodeReview.first.visible_date).to eq nil
      expect(CodeReview.first.due_date).to eq nil
    end

    context 'with objectives' do
      scenario 'form defaults with 3 objective fields' do
        within('ul#objective-fields') do
          expect(page).to have_selector('li', count: 3)
        end
      end

      scenario 'allows more objectives to be added', js: true do
        click_link 'Add objective'
        within('ul#objective-fields') do
          expect(page).to have_selector('li', count: 4)
        end
      end

      scenario 'requires at least one objective to be added' do
        fill_in 'Title', with: code_review.title
        click_button 'Create Code review'
        expect(page).to have_content 'Objectives must be present'
      end
    end
  end

  context 'as a student' do
    let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }

    scenario 'you are not authorized' do
      login_as(student, scope: :student)
      visit new_course_code_review_path(student.course)
      expect(page).to have_content 'not authorized'
    end
  end
end

feature 'editing a code review' do
  let(:code_review) { FactoryBot.create(:code_review) }

  scenario 'as a guest' do
    visit edit_course_code_review_path(code_review.course, code_review)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student' do
    student = FactoryBot.create(:student, courses: [code_review.course])
    login_as(student, scope: :student)
    visit edit_course_code_review_path(code_review.course, code_review)
    expect(page).to have_content 'You are not authorized to access this page.'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, current_course: code_review.course) }

    before do
      login_as(admin, scope: :admin)
      visit edit_course_code_review_path(code_review.course, code_review)
    end

    scenario 'with valid input' do
      fill_in 'Title', with: 'Another title'
      click_button 'Update Code review'
      expect(page).to have_content 'Code review updated'
    end

    scenario 'with invalid input' do
      fill_in 'Title', with: ''
      click_button 'Update Code review'
      expect(page).to have_content "can't be blank"
    end

    scenario 'with dates' do
      code_review.visible_date = nil
      code_review.due_date = nil
      code_review.save
      travel_to Date.parse('2021-01-04') do
        visit edit_course_code_review_path(code_review.course, code_review)
        find('#always_visible').set false
        click_button 'Update Code review'
        expect(CodeReview.first.visible_date).to_not eq nil
        expect(CodeReview.first.due_date).to eq CodeReview.first.visible_date + 9.hours
      end
    end

    scenario 'part-time code review with dates' do
      code_review.visible_date = nil
      code_review.due_date = nil
      code_review.save
      code_review.course.update_columns(parttime: true)
      travel_to Date.parse('2021-01-04') do
        visit edit_course_code_review_path(code_review.course, code_review)
        fill_in 'Title', with: code_review.title
        fill_in 'code_review_objectives_attributes_0_content', with: 'objective'
        find('#always_visible').set false
        click_button 'Update Code review'
        expect(CodeReview.first.visible_date).to_not eq nil
        expect(CodeReview.first.due_date).to eq CodeReview.first.visible_date + 1.week
      end
    end

    scenario 'always visible' do
      fill_in 'Title', with: code_review.title
      fill_in 'code_review_objectives_attributes_0_content', with: 'objective'
      find('#always_visible').set true
      click_button 'Update Code review'
      expect(CodeReview.first.visible_date).to eq nil
      expect(CodeReview.first.due_date).to eq nil
    end

    scenario 'removing objectives', js: true do
      objective_count = code_review.objectives.count
      within('ul#objective-fields') do
        first(:link, 'x').click
      end
      click_button 'Update Code review'
      sleep 1
      expect(code_review.objectives.count).to eq objective_count - 1
    end

    scenario 'adding objectives', js: true do
      objective_count = code_review.objectives.count
      click_link 'Add objective'
      within('ul#objective-fields') do
        all('input').last.set 'The last objective'
      end
      click_button 'Update Code review'
      sleep 1
      expect(code_review.objectives.count).to eq objective_count + 1
    end

    scenario 'reordering objectives', js: true do
      click_link 'Add objective'
      within('ul#objective-fields') do
        all('.objective-number').first.set '2'
        all('.objective-content').first.set 'The last objective'
        all('.objective-number').last.set '1'
        all('.objective-content').last.set 'The first objective'
      end
      click_button 'Update Code review'
      sleep 1
      code_review.reload
      expect(code_review.objectives.last.content).to eq 'The last objective'
    end

    scenario 'adding Github URL', vcr: true do
      fill_in 'Github URL', with: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/main/README.md"
      click_button 'Update Code review'
      expect(page).to have_content 'testing'
    end

    scenario 'adding invalid Github URL', vcr: true do
      fill_in 'Github URL', with: "https://github.com/#{ENV['GITHUB_CURRICULUM_ORGANIZATION']}/testing/blob/main/does_not_exist.md"
      click_button 'Update Code review'
      expect(page).to have_content 'Unable to pull code review from Github'
      expect(code_review.content).to eq 'test content'
    end
  end

  context 'as a student' do
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed) }

    scenario 'you are not authorized' do
      login_as(student, scope: :student)
      visit edit_course_code_review_path(code_review.course, code_review)
      expect(page).to have_content 'not authorized'
    end
  end
end

feature 'copying an existing code review' do
  let(:admin) { FactoryBot.create(:admin, :with_course) }

  before { login_as(admin, scope: :admin) }

  scenario 'successful copy of code review' do
    code_review = FactoryBot.create(:code_review, course: admin.current_course)
    visit new_course_code_review_path(admin.current_course)
    select code_review.title, from: 'code_review_id'
    click_button 'Copy'
    expect(page).to have_content 'Code review successfully copied.'
  end

  scenario 'successful copy of code review to course that is not admin current_course' do
    other_course = FactoryBot.create(:course)
    code_review = FactoryBot.create(:code_review, course: admin.current_course)
    visit new_course_code_review_path(other_course)
    select code_review.title, from: 'code_review_id'
    click_button 'Copy'
    expect(page).to have_content 'Code review successfully copied.'
    expect(admin.current_course.code_reviews.count).to eq 1
    expect(other_course.code_reviews.count).to eq 1
  end
end

feature 'view the code reviews tab on the student show page' do
  let(:course) { FactoryBot.create(:course) }
  let(:admin) { FactoryBot.create(:admin, current_course: course) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, course: course) }
  let!(:code_review) { FactoryBot.create(:code_review, course: course) }
  let!(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }
  let!(:review) { FactoryBot.create(:review, submission: submission) }

  before { login_as(admin, scope: :admin) }

  scenario 'an instructor looks at a code review and sees whether a student passed', :stub_mailgun do
    visit course_student_path(student.course, student)
    expect(page).to have_css '.submission-success'
  end
end

feature 'deleting a code review' do
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:code_review) { FactoryBot.create(:code_review) }

  before { login_as(admin, scope: :admin) }

  scenario 'without existing submissions' do
    visit course_code_review_path(code_review.course, code_review)
    click_link 'Delete'
    expect(page).to have_content "#{code_review.title} has been deleted."
  end

  scenario 'with existing submissions' do
    FactoryBot.create(:submission, code_review: code_review)
    visit course_code_review_path(code_review.course, code_review)
    click_link 'Delete'
    expect(page).to have_content "Cannot delete a code review with existing submissions."
  end
end

feature 'exporting code review submissions info to a file' do
  let(:code_review) { FactoryBot.create(:code_review) }

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, :with_course) }
    before { login_as(admin, scope: :admin) }

    scenario 'exports all submissions needing review from code review submissions needing review list' do
      FactoryBot.create(:submission, code_review: code_review)
      visit code_review_submissions_path(code_review)
      click_link 'export-btn'
      filename = Rails.root.join('tmp','students.txt')
      expect(filename).to exist
    end

    scenario 'exports all submissions from code review show page' do
      FactoryBot.create(:submission, code_review: code_review)
      visit course_code_review_path(code_review.course, code_review)
      click_link 'export-btn'
      filename = Rails.root.join('tmp','students.txt')
      expect(filename).to exist
    end
  end

  context 'as a student' do
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed) }
    before { login_as(student, scope: :student) }
    scenario 'without permission to export code review submissions' do
      FactoryBot.create(:submission, code_review: code_review)
      visit code_review_export_path(code_review)
      expect(page).to have_content "You are not authorized to access this page."
    end
  end
end
