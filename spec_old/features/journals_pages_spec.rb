feature "Bulk viewing journal submissions" do
  scenario 'as a guest' do
    visit journals_path
    expect(page).to have_content 'You are not authorized'
  end

 context "as a student" do
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed, :with_course) }

    before { login_as(student, scope: :student) }

    scenario 'does not allow access if no title provided' do
      visit journals_path
      expect(page).to have_content "You are not authorized"
    end

    scenario 'does not allow access if invalid title provided' do
      visit journals_path(title: 'invalid title')
      expect(page).to have_content "You are not authorized"
    end

    scenario 'redirects to appropriate student course containing that journal topic' do
      journal = FactoryBot.create(:journal, course: student.course)
      other_course = FactoryBot.create(:course)
      other_journal = FactoryBot.create(:journal, course: other_course)
      visit journals_path(title: journal.title)
      expect(page).to have_current_path course_code_review_path(student.course, journal)
    end
  end

  context "as an admin" do
    let(:ft_cohort) { FactoryBot.create(:ft_cohort) }
    let(:pt_cohort) { FactoryBot.create(:pt_intro_cohort) }
    let(:admin) { FactoryBot.create(:admin, current_course: ft_cohort.courses.first) }

    before { login_as(admin, scope: :admin) }

    scenario 'redirects if visit cohort_journals_path without title' do
      visit cohort_journals_path(ft_cohort)
      expect(page).to have_current_path cohort_path(ft_cohort)
    end

    scenario "can view list of reflection topics from all cohorts" do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first)
      journal_2 = FactoryBot.create(:journal, course: pt_cohort.courses.first)
      code_review = FactoryBot.create(:code_review, course: ft_cohort.courses.first)
      visit journals_path
      expect(page).to have_content "reflections"
      expect(page).to have_content "all cohorts"
      expect(page).to_not have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content journal_1.title
      expect(page).to have_content journal_2.title
      expect(page).to_not have_content code_review.title
    end

    scenario "can view list of reflection topics for individual cohort" do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first)
      journal_2 = FactoryBot.create(:journal, course: ft_cohort.courses.last)
      journal_3 = FactoryBot.create(:journal, course: pt_cohort.courses.first)
      visit cohort_path(ft_cohort)
      expect(page).to have_content "reflections"
      expect(page).to have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content journal_1.title
      expect(page).to have_content journal_2.title
      expect(page).to_not have_content journal_3.title
      visit cohort_path(pt_cohort)
      expect(page).to have_content "reflections"
      expect(page).to have_content pt_cohort.description
      expect(page).to_not have_content ft_cohort.description
      expect(page).to have_content journal_3.title
      expect(page).to_not have_content journal_1.title
      expect(page).to_not have_content journal_2.title
    end

    scenario 'can view submissions for a particular cohort for a particular reflection assignment' do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first, title: 'reflection assignment 1')
      journal_2 = FactoryBot.create(:journal, course: ft_cohort.courses.last, title: 'reflection assignment 2')
      journal_3 = FactoryBot.create(:journal, course: pt_cohort.courses.first, title: 'reflection assignment 1')
      submission_1 = FactoryBot.create(:journal_submission, code_review: journal_1)
      submission_2 = FactoryBot.create(:journal_submission, code_review: journal_2)
      submission_3 = FactoryBot.create(:journal_submission, code_review: journal_3)
      visit cohort_path(ft_cohort)
      click_on 'reflection assignment 1'
      expect(page).to have_content 'reflection assignment 1'
      expect(page).to have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content submission_1.journal
      expect(page).to_not have_content submission_3.journal
      expect(page).to_not have_content submission_2.journal
      expect(page).to have_content submission_1.created_at.strftime("%b %-d %Y")
    end

    scenario 'can view submissions from all cohorts for a particular reflection assignment' do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first, title: 'reflection assignment 1')
      journal_2 = FactoryBot.create(:journal, course: ft_cohort.courses.last, title: 'reflection assignment 2')
      journal_3 = FactoryBot.create(:journal, course: pt_cohort.courses.first, title: 'reflection assignment 1')
      submission_1 = FactoryBot.create(:journal_submission, code_review: journal_1)
      submission_2 = FactoryBot.create(:journal_submission, code_review: journal_2)
      submission_3 = FactoryBot.create(:journal_submission, code_review: journal_3)
      visit cohort_journals_path(ft_cohort, title: 'reflection assignment 1')
      click_on '[view submissions for all cohorts]'
      expect(page).to have_content 'reflection assignment 1'
      expect(page).to_not have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content submission_1.journal
      expect(page).to have_content submission_3.journal
      expect(page).to_not have_content submission_2.journal
      expect(page).to have_content submission_1.created_at.strftime("%b %-d %Y")
    end

    scenario 'can view individual journal submission by clicking on date in journals list' do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first)
      submission_1 = FactoryBot.create(:journal_submission, code_review: journal_1)
      visit journals_path(title: journal_1.title)
      click_on journal_1.created_at.strftime("%b %-d %Y")
      expect(page).to have_content "Submission for #{journal_1.title}"
      expect(page).to have_content submission_1.student.name
    end
  end
end
