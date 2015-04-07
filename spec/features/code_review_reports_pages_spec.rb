feature 'code_review report', vcr: true do
  it 'shows a table with all of the students and their grades' do
    student = FactoryGirl.create(:student)
    code_review = FactoryGirl.create(:code_review, cohort: student.cohort)
    submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
    review = FactoryGirl.create(:review, submission: submission)
    grade = FactoryGirl.create(:passing_grade, review: review, requirement: code_review.requirements.first)
    admin = FactoryGirl.create(:admin, current_cohort: student.cohort)
    login_as(admin, scope: :admin)
    visit cohort_code_reviews_path(code_review.cohort)
    click_link 'Grades report'
    expect(page).to have_content grade.score.value
  end

  it "sorts the table by the student's total score for that code_review" do
    student = FactoryGirl.create(:student)
    better_student = FactoryGirl.create(:student, cohort: student.cohort)
    code_review = FactoryGirl.create(:code_review, cohort: student.cohort)
    submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
    better_submission = FactoryGirl.create(:submission, code_review: code_review, student: better_student)
    review = FactoryGirl.create(:review, submission: submission)
    better_review = FactoryGirl.create(:review, submission: better_submission)
    failing_grade = FactoryGirl.create(:failing_grade, review: review, requirement: code_review.requirements.first)
    passing_grade = FactoryGirl.create(:passing_grade, review: better_review, requirement: code_review.requirements.first)
    admin = FactoryGirl.create(:admin, current_cohort: student.cohort)
    login_as(admin, scope: :admin)
    visit cohort_code_reviews_path(code_review.cohort)
    click_link 'Grades report'
    within('tr', :text => better_student.name) do
      expect(page).to have_content passing_grade.score.value
    end
  end

  context 'visiting as a student' do
    it 'is not authorized' do
      student = FactoryGirl.create(:student)
      code_review = FactoryGirl.create(:code_review)
      login_as(student, scope: :student)
      visit code_review_report_path(code_review)
      expect(page).to have_content("not authorized")
    end
  end
end
