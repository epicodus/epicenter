feature 'index page' do
  let!(:code_review) { FactoryGirl.create(:code_review) }

  scenario 'not logged in' do
    visit course_code_reviews_path(code_review.course)
    expect(page).to have_content 'need to sign in'
  end

  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: code_review.course) }
    before { login_as(student, scope: :student) }

    scenario "but isn't this student's course" do
      another_course = FactoryGirl.create(:course)
      visit course_code_reviews_path(another_course)
      expect(page).to have_content 'not authorized'
    end

    scenario 'shows all code reviews' do
      another_code_review = FactoryGirl.create(:code_review, title: 'another_code_review', course: code_review.course)
      visit course_code_reviews_path(code_review.course)
      expect(page).to have_content code_review.title
      expect(page).to have_content another_code_review.title
    end

    scenario 'shows if the student has submitted an code_review' do
      FactoryGirl.create(:submission, code_review: code_review, student: student)
      visit course_code_reviews_path(code_review.course)
      expect(page).to have_content 'Submitted'
      expect(page).to_not have_content 'Not submitted'
    end

    scenario 'shows if the code_review has been graded', :vcr do
      submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
      FactoryGirl.create(:passing_review, submission: submission)
      visit course_code_reviews_path(code_review.course)
      expect(page).to have_content 'Reviewed'
      expect(page).to_not have_content 'Submitted'
    end

    scenario 'links to code_review show page' do
      visit course_code_reviews_path(code_review.course)
      click_link code_review.title
      expect(page).to have_content code_review.title
      expect(page).to have_content code_review.objectives.first.content
    end

    scenario 'does not have button to save order of code reviews' do
      visit course_code_reviews_path(code_review.course)
      expect(page).to_not have_button 'Save order'
    end
  end

  context 'when visiting as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:code_review) { FactoryGirl.create(:code_review) }

    before { login_as(admin, scope: :admin) }

    scenario 'has a link to create a new code review' do
      visit course_code_reviews_path(code_review.course)
      click_on 'New Code Review'
      expect(page).to have_content 'New Code Review'
    end

    scenario 'shows the number of submissions needing review for each code_review' do
      FactoryGirl.create(:submission, code_review: code_review)
      visit course_code_reviews_path(code_review.course)
      expect(page).to have_content '1 new submission'
    end

    scenario 'admin clicks on number of submission badge and is taken to submissions index of that code_review' do
      FactoryGirl.create(:submission, code_review: code_review)
      visit course_code_reviews_path(code_review.course)
      click_link '1 new submission'
      expect(page).to have_content "Submissions for #{code_review.title}"
    end

    scenario 'has a button to save order of code reviews' do
      visit course_code_reviews_path(code_review.course)
      expect(page).to have_button 'Save order'
    end

    scenario 'changes lesson order' do
      another_assesment = FactoryGirl.create(:code_review, course: code_review.course)
      visit course_code_reviews_path(code_review.course)
      click_on 'Save order'
      expect(page).to have_content 'Order has been saved'
    end
  end
end

feature 'show page' do
  let(:code_review) { FactoryGirl.create(:code_review) }

  scenario 'not signed in' do
    visit code_review_path(code_review)
    expect(page).to have_content 'need to sign in'
  end

  context 'when visiting as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before do
      login_as(admin, scope: :admin)
      visit code_review_path(code_review)
    end

    scenario 'has a link to edit code_review' do
      click_on 'Edit'
      expect(page).to have_content 'Edit Code Review'
    end

    scenario 'has a link to delete code_review' do
      click_on 'Delete'
      expect(page).to have_content "#{code_review.title} has been deleted"
    end

    scenario 'has a link to create a new code_review' do
      click_on 'New'
      expect(page).to have_content 'New Code Review'
    end
  end

  context 'when visiting as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed, course: code_review.course) }
    before { login_as(student, scope: :student) }
    subject { page }

    scenario "but this code review is not part of your course" do
      code_review_of_another_course = FactoryGirl.create(:code_review)
      visit code_review_path(code_review_of_another_course)
      expect(page).to have_content 'not authorized'
    end

    context 'before submitting' do
      before do
        visit code_review_path(code_review)
      end

      it { is_expected.to have_button 'Submit' }
      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end

    context 'when submitting' do
      before { visit code_review_path(code_review) }

      scenario 'with valid input' do
        fill_in 'submission_link', with: 'http://github.com'
        click_button 'Submit'
        is_expected.to have_content 'Thank you for submitting'
      end

      scenario 'with invalid input' do
        click_button 'Submit'
        is_expected.to have_content "can't be blank"
      end
    end

    context 'after having submitted' do
      before do
        FactoryGirl.create(:submission, code_review: code_review, student: student)
        visit code_review_path(code_review)
      end

      it { is_expected.to have_button 'Resubmit' }
      it { is_expected.to have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end

    context 'after submission has been reviewed', :vcr do
      let(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }
      let!(:review) { FactoryGirl.create(:passing_review, submission: submission) }

      before do
        visit code_review_path(code_review)
      end

      it { is_expected.to_not have_content 'pending review' }
      it { is_expected.to have_content review.note }
      it { is_expected.to have_content 'Meets expectations' }
    end

    context 'after resubmitting', :vcr do
      let(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }

      before do
        FactoryGirl.create(:passing_review, submission: submission)
        visit code_review_path(code_review)
        click_on 'Resubmit'
      end

      it { is_expected.to have_content 'Submission updated' }
      it { is_expected.to have_content 'pending review' }
      it { is_expected.to_not have_link 'has been reviewed' }
    end
  end
end

feature 'creating an code_review' do
  scenario 'not signed in' do
    visit new_code_review_path
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:code_review) { FactoryGirl.build(:code_review) }
    let(:admin) { FactoryGirl.create(:admin) }

    before do
      login_as(admin, scope: :admin)
      visit new_code_review_path
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
        click_link 'Add Objective'
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
      visit new_code_review_path
      expect(page).to have_content 'not authorized'
    end
  end
end

feature 'editing an code_review' do
  let(:code_review) { FactoryGirl.create(:code_review) }

  scenario 'not signed in' do
    visit edit_code_review_path(code_review)
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }

    before do
      login_as(admin, scope: :admin)
      visit edit_code_review_path(code_review)
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
      click_link 'Add Objective'
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
      visit edit_code_review_path(code_review)
      expect(page).to have_content 'not authorized'
    end
  end
end

feature 'copying an existing code review' do
  let(:admin) { FactoryGirl.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'successful copy of code review' do
    code_review = FactoryGirl.create(:code_review, course: admin.current_course)
    visit new_code_review_path
    select code_review.title, from: 'code_review_id'
    click_button 'Copy'
    expect(page).to have_content 'Code review successfully copied.'
  end
end

feature 'view the Code Reviews tab' do
  before do
    mailgun_client = spy("mailgun client")
    allow(Mailgun::Client).to receive(:new) { mailgun_client }
  end

  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:user_with_score_of_6) }


  before { login_as(admin, scope: :admin) }

  scenario 'an instructor looks at a code review and sees whether a student passed' do
    visit student_path(student)
    find('#student-nav li.student-code-reviews').click
    expect(page).to have_content "Pass"
  end


  scenario 'a user clicks on notes and a modal opens' do
    visit student_path(student)
    find('#student-nav li.student-code-reviews').click
    click_link 'Notes'
    expect(page).to have_content("Great job!")
  end
end

feature 'deleting a code review' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:code_review) { FactoryGirl.create(:code_review) }

  before { login_as(admin, scope: :admin) }

  scenario 'without existing submissions' do
    visit code_review_path(code_review)
    click_link 'Delete'
    expect(page).to have_content "#{code_review.title} has been deleted."
  end

  scenario 'with existing submissions' do
    submission = FactoryGirl.create(:submission, code_review: code_review)
    visit code_review_path(code_review)
    click_link 'Delete'
    expect(page).to have_content "Cannot delete a code review with existing submissions."
  end
end
