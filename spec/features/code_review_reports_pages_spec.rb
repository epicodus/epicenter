feature 'code_review report' do
  it 'shows a table with all of the students and their grades', :stub_mailgun do
    student = FactoryGirl.create(:student)
    code_review = FactoryGirl.create(:code_review, course: student.course)
    submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
    review = FactoryGirl.create(:review, submission: submission)
    grade = FactoryGirl.create(:passing_grade, review: review, objective: code_review.objectives.first)
    admin = FactoryGirl.create(:admin, current_course: student.course)
    login_as(admin, scope: :admin)
    visit course_path(code_review.course)
    click_link 'Grades report'
    expect(page).to have_css '.submission-success'
  end

  it "sorts the table by the student's total score for that code_review", :stub_mailgun do
    student = FactoryGirl.create(:student)
    better_student = FactoryGirl.create(:student, course: student.course)
    code_review = FactoryGirl.create(:code_review, course: student.course)
    submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
    better_submission = FactoryGirl.create(:submission, code_review: code_review, student: better_student)
    review = FactoryGirl.create(:review, submission: submission)
    better_review = FactoryGirl.create(:review, submission: better_submission)
    failing_grade = FactoryGirl.create(:failing_grade, review: review, objective: code_review.objectives.first)
    passing_grade = FactoryGirl.create(:passing_grade, review: better_review, objective: code_review.objectives.first)
    admin = FactoryGirl.create(:admin, current_course: student.course)
    login_as(admin, scope: :admin)
    visit course_path(code_review.course)
    click_link 'Grades report'
    within('tr', text: better_student.name) do
      expect(page).to have_css '.submission-success'
    end
    within('tr', text: student.name) do
      expect(page).to have_css '.submission-fail'
    end
  end

  context 'visiting as a student' do
    it 'is not authorized' do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      code_review = FactoryGirl.create(:code_review)
      login_as(student, scope: :student)
      visit course_code_review_report_path(student.course, code_review)
      expect(page).to have_content("not authorized")
    end
  end
end
