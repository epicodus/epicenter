feature 'assessment report', vcr: true do
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

  it "sorts the table by the student's total score for that assessment" do
    student = FactoryGirl.create(:student)
    better_student = FactoryGirl.create(:student, cohort: student.cohort)
    assessment = FactoryGirl.create(:assessment, cohort: student.cohort)
    submission = FactoryGirl.create(:submission, assessment: assessment, student: student)
    better_submission = FactoryGirl.create(:submission, assessment: assessment, student: better_student)
    review = FactoryGirl.create(:review, submission: submission)
    better_review = FactoryGirl.create(:review, submission: better_submission)
    failing_grade = FactoryGirl.create(:failing_grade, review: review, requirement: assessment.requirements.first)
    passing_grade = FactoryGirl.create(:passing_grade, review: better_review, requirement: assessment.requirements.first)
    admin = FactoryGirl.create(:admin, current_cohort: student.cohort)
    login_as(admin, scope: :admin)
    visit cohort_assessments_path(assessment.cohort)
    click_link 'Grades report'
    within('tr', :text => better_student.name) do
      expect(page).to have_content passing_grade.score.value
    end
  end

  context 'visiting as a student' do
    it 'is not authorized' do
      student = FactoryGirl.create(:student)
      assessment = FactoryGirl.create(:assessment)
      login_as(student, scope: :student)
      visit assessment_report_path(assessment)
      expect(page).to have_content("not authorized")
    end
  end
end
