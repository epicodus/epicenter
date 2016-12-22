feature 'viewing the code review index page' do
  let!(:code_review) { FactoryGirl.create(:code_review) }

  scenario 'as a guest' do
    visit course_path(code_review.course)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: code_review.course) }
    before { login_as(student, scope: :student) }

    scenario 'redirects the student to the root path' do
      visit course_path(code_review.course)
      expect(page).to have_content 'You are not authorized'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:code_review) { FactoryGirl.create(:code_review) }

    before { login_as(admin, scope: :admin) }

    scenario 'has a link to create a new code review' do
      visit course_path(code_review.course)
      click_on 'New'
      expect(page).to have_content 'New code review'
    end

    scenario 'shows the number of submissions needing review for each code_review' do
      FactoryGirl.create(:submission, code_review: code_review)
      visit course_path(code_review.course)
      expect(page).to have_content '1 new submission'
    end

    scenario 'admin clicks on number of submission badge and is taken to submissions index of that code_review' do
      FactoryGirl.create(:submission, code_review: code_review)
      visit course_path(code_review.course)
      click_link '1 new submission'
      expect(page).to have_content "Submissions for #{code_review.title}"
    end

    scenario 'has a button to save order of code reviews' do
      visit course_path(code_review.course)
      expect(page).to have_button 'Save order'
    end

    scenario 'changes lesson order' do
      FactoryGirl.create(:code_review, course: code_review.course)
      visit course_path(code_review.course)
      click_on 'Save order'
      expect(page).to have_content 'Order has been saved'
    end
  end
end

feature 'visiting the code review show page' do
  let(:code_review) { FactoryGirl.create(:code_review) }

  scenario 'as a guest' do
    visit course_code_review_path(code_review.course, code_review)
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
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
  end

  context 'as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: code_review.course) }
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

    context 'when submitting' do
      before { visit course_code_review_path(code_review.course, code_review) }

      scenario 'with valid input' do
        fill_in 'submission_link', with: 'http://github.com'
        click_button 'Submit'
        is_expected.to have_content 'Thank you for submitting'
        is_expected.to have_content code_review.title
      end

      scenario 'with invalid input' do
        click_button 'Submit'
        is_expected.to have_content "can't be blank"
      end
    end

    context 'after having submitted' do
      before do
        FactoryGirl.create(:submission, code_review: code_review, student: student)
        visit course_code_review_path(code_review.course, code_review)
      end

      it { is_expected.to have_button 'Resubmit' }
      it { is_expected.to have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end

    context 'after submission has been reviewed', :stub_mailgun do
      let(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }
      let!(:review) { FactoryGirl.create(:passing_review, submission: submission) }

      before { visit course_code_review_path(code_review.course, code_review) }

      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to have_content review.note }
      it { is_expected.to have_content 'Meets expectations' }
    end

    context 'after resubmitting', :stub_mailgun do
      let(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }

      before do
        FactoryGirl.create(:passing_review, submission: submission)
        visit course_code_review_path(code_review.course, code_review)
      end

      scenario 'successfully' do
        click_button 'Resubmit'
        expect(page).to have_content 'Submission updated'
        expect(page).to have_content 'pending review'
      end

      scenario 'unsuccessfully' do
        fill_in 'submission_link', with: ''
        click_button 'Resubmit'
        expect(page).to have_content "Please correct these problems: Link can't be blank"
      end
    end
  end
end

feature 'creating a code review' do
  let(:course) { FactoryGirl.create(:course) }

  scenario 'as a guest' do
    visit new_course_code_review_path(course)
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:code_review) { FactoryGirl.build(:code_review) }
    let(:admin) { FactoryGirl.create(:admin) }

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
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

    scenario 'you are not authorized' do
      login_as(student, scope: :student)
      visit new_course_code_review_path(student.course)
      expect(page).to have_content 'not authorized'
    end
  end
end

feature 'editing a code review' do
  let(:code_review) { FactoryGirl.create(:code_review) }

  scenario 'as a guest' do
    visit edit_course_code_review_path(code_review.course, code_review)
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }

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

    scenario 'removing objectives', js: true do
      objective_count = code_review.objectives.count
      within('ul#objective-fields') do
        first(:link, 'x').click
      end
      click_button 'Update Code review'
      expect(code_review.objectives.count).to eq objective_count - 1
    end

    scenario 'adding objectives', js: true do
      objective_count = code_review.objectives.count
      click_link 'Add objective'
      within('ul#objective-fields') do
        all('input').last.set 'The last objective'
      end
      click_button 'Update Code review'
      expect(code_review.objectives.count).to eq objective_count + 1
    end
  end

  context 'as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

    scenario 'you are not authorized' do
      login_as(student, scope: :student)
      visit edit_course_code_review_path(code_review.course, code_review)
      expect(page).to have_content 'not authorized'
    end
  end
end

feature 'copying an existing code review' do
  let(:admin) { FactoryGirl.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'successful copy of code review' do
    code_review = FactoryGirl.create(:code_review, course: admin.current_course)
    visit new_course_code_review_path(admin.current_course)
    select code_review.title, from: 'code_review_id'
    click_button 'Copy'
    expect(page).to have_content 'Code review successfully copied.'
  end
end

feature 'view the code reviews tab on the student show page' do
  let(:course) { FactoryGirl.create(:course) }
  let(:admin) { FactoryGirl.create(:admin, current_course: course) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: course) }
  let!(:code_review) { FactoryGirl.create(:code_review, course: course) }
  let!(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }
  let!(:review) { FactoryGirl.create(:review, submission: submission) }

  before { login_as(admin, scope: :admin) }

  scenario 'an instructor looks at a code review and sees whether a student passed', :stub_mailgun do
    visit course_student_path(student.course, student)
    expect(page).to have_css '.submission-success'
  end

  scenario 'a user clicks on notes and a modal opens', :stub_mailgun do
    visit course_student_path(student.course, student)
    click_link 'Notes'
    expect(page).to have_content("Great job!")
  end
end

feature 'deleting a code review' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:code_review) { FactoryGirl.create(:code_review) }

  before { login_as(admin, scope: :admin) }

  scenario 'without existing submissions' do
    visit course_code_review_path(code_review.course, code_review)
    click_link 'Delete'
    expect(page).to have_content "#{code_review.title} has been deleted."
  end

  scenario 'with existing submissions' do
    FactoryGirl.create(:submission, code_review: code_review)
    visit course_code_review_path(code_review.course, code_review)
    click_link 'Delete'
    expect(page).to have_content "Cannot delete a code review with existing submissions."
  end
end

feature 'exporting code review details to a file' do
  let(:code_review) { FactoryGirl.create(:code_review) }

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }
    scenario 'exports info on all submissions for a code review' do
      FactoryGirl.create(:submission, code_review: code_review)
      visit code_review_submissions_path(code_review)
      click_link 'export-btn'
      filename = Rails.root.join('tmp','students.txt')
      expect(filename).to exist
    end
  end

  context 'as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
    before { login_as(student, scope: :student) }
    scenario 'without permission to export code review submissions' do
      FactoryGirl.create(:submission, code_review: code_review)
      visit code_review_export_path(code_review)
      expect(page).to have_content "You are not authorized to access this page."
    end
  end
end
