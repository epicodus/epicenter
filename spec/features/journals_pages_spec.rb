feature "Viewing list of all journal topics" do
  scenario 'as a guest' do
    visit journals_path
    expect(page).to have_content 'You are not authorized'
  end

  scenario "as a student" do
    student = FactoryBot.create(:student)
    login_as(student, scope: :student)
    visit journals_path
    expect(page).to have_content "You are not authorized"
  end

  context "as an admin" do
    let(:ft_cohort) { FactoryBot.create(:ft_cohort) }
    let(:pt_cohort) { FactoryBot.create(:pt_intro_cohort) }
    let(:admin) { FactoryBot.create(:admin, current_course: ft_cohort.courses.first) }

    before { login_as(admin, scope: :admin) }

    scenario "can view list of journal topics from all cohorts" do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first)
      journal_2 = FactoryBot.create(:journal, course: pt_cohort.courses.first)
      code_review = FactoryBot.create(:code_review, course: ft_cohort.courses.first)
      visit journals_path
      expect(page).to have_content "Journals"
      expect(page).to_not have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content journal_1.title
      expect(page).to have_content journal_2.title
      expect(page).to_not have_content code_review.title
    end

    scenario "can view list of journal topics for individual cohort" do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first)
      journal_2 = FactoryBot.create(:journal, course: ft_cohort.courses.last)
      journal_3 = FactoryBot.create(:journal, course: pt_cohort.courses.first)
      visit cohort_journals_path(ft_cohort)
      expect(page).to have_content "Journals"
      expect(page).to have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content journal_1.title
      expect(page).to have_content journal_2.title
      expect(page).to_not have_content journal_3.title
      visit cohort_journals_path(pt_cohort)
      expect(page).to have_content "Journals"
      expect(page).to have_content pt_cohort.description
      expect(page).to_not have_content ft_cohort.description
      expect(page).to have_content journal_3.title
      expect(page).to_not have_content journal_1.title
      expect(page).to_not have_content journal_2.title
    end

    scenario 'can view submissions from all cohorts for a particular journal assignment' do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first, title: 'journal assignment 1')
      journal_2 = FactoryBot.create(:journal, course: ft_cohort.courses.last, title: 'journal assignment 2')
      journal_3 = FactoryBot.create(:journal, course: pt_cohort.courses.first, title: 'journal assignment 1')
      submission_1 = FactoryBot.create(:journal_submission, code_review: journal_1)
      submission_2 = FactoryBot.create(:journal_submission, code_review: journal_2)
      submission_3 = FactoryBot.create(:journal_submission, code_review: journal_3)
      visit journals_path
      click_on 'journal assignment 1'
      expect(page).to have_content 'journal assignment 1'
      expect(page).to_not have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content submission_1.journal
      expect(page).to have_content submission_3.journal
      expect(page).to_not have_content submission_2.journal
      expect(page).to have_content submission_1.created_at.strftime("%b %-d %Y")
    end

    scenario 'can view submissions for a particular cohort for a particular journal assignment' do
      journal_1 = FactoryBot.create(:journal, course: ft_cohort.courses.first, title: 'journal assignment 1')
      journal_2 = FactoryBot.create(:journal, course: ft_cohort.courses.last, title: 'journal assignment 2')
      journal_3 = FactoryBot.create(:journal, course: pt_cohort.courses.first, title: 'journal assignment 1')
      submission_1 = FactoryBot.create(:journal_submission, code_review: journal_1)
      submission_2 = FactoryBot.create(:journal_submission, code_review: journal_2)
      submission_3 = FactoryBot.create(:journal_submission, code_review: journal_3)
      visit cohort_journals_path(ft_cohort)
      click_on 'journal assignment 1'
      expect(page).to have_content 'journal assignment 1'
      expect(page).to have_content ft_cohort.description
      expect(page).to_not have_content pt_cohort.description
      expect(page).to have_content submission_1.journal
      expect(page).to_not have_content submission_3.journal
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
