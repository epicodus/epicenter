feature 'assessment report' do
  let(:student) { FactoryGirl.create(:student) }
  let(:assessment) { FactoryGirl.create(:assessment, cohort: student.cohort) }
  let(:admin) { FactoryGirl.create(:admin, current_cohort: student.cohort) }
  let(:submission) { FactoryGirl.create(:submission, assessment: assessment, student: student) }
  let(:review) { FactoryGirl.create(:review, submission: submission) }
  let(:grade) { FactoryGirl.create(:failing_grade, review: review, requirement: assessment.requirements.first) }

  it 'shows a table with all of the students and their grades' do
    login_as(admin, scope: :admin)
    visit cohort_assessments_path(assessment.cohort)
    click_link 'Grades report'
    expect(page).to have_content grade.score.value
  end

  it "sorts the table by the student's total score for that assessment" do
    better_student = FactoryGirl.create(:student, cohort: student.cohort)
    better_submission = FactoryGirl.create(:submission, assessment: assessment, student: better_student)
    better_review = FactoryGirl.create(:review, submission: better_submission)
    passing_grade = FactoryGirl.create(:passing_grade, review: better_review, requirement: assessment.requirements.first)

    login_as(admin, scope: :admin)
    visit cohort_assessments_path(assessment.cohort)
    click_link 'Grades report'
    within('tr', :text => better_student.name) do
      expect(page).to have_content passing_grade.score.value
    end
  end

  scenario 'visiting as a student' do
    login_as(student, scope: :student)
    visit assessment_report_path(assessment)
    expect(page).to have_content "You are not authorized to access this page."
  end
end
