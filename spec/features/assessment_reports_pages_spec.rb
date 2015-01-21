feature 'assessment report' do
  it 'shows a table with all of the students and their grades' do
    student = FactoryGirl.create(:student)
    assessment = FactoryGirl.create(:assessment)
    submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
    grade = FactoryGirl.create(:passing_grade, user: student)

    admin = FactoryGirl.create(:admin)
    login_as(admin, scope: :admin)

    visit cohort_assessments_path(assessment.cohort)
    click_link 'Grades report'
    expect(page).to have_content grade.score.value
  end
end
