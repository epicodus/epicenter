feature 'assessment report' do
  it 'shows a table with all of the students and their grades' do
    student = FactoryGirl.create(:student)
    assessment = FactoryGirl.create(:assessment, cohort: student.cohort)
    submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
    review = FactoryGirl.create(:review, submission: submission)
    grade = FactoryGirl.create(:passing_grade, review: review, requirement: assessment.requirements.first)
    admin = FactoryGirl.create(:admin, current_cohort: student.cohort)
    login_as(admin, scope: :admin)
    visit cohort_assessments_path(assessment.cohort)
    click_link 'Grades report'
    expect(page).to have_content grade.score.value
  end
end
