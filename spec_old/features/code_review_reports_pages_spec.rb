feature 'code_review report' do
  it 'shows a table with all of the students and their grades', :stub_mailgun do
    student = FactoryBot.create(:student, :with_course)
    code_review = FactoryBot.create(:code_review, course: student.course)
    submission = FactoryBot.create(:submission, code_review: code_review, student: student)
    review = FactoryBot.create(:review, submission: submission)
    grade = FactoryBot.create(:passing_grade, review: review, objective: code_review.objectives.first)
    admin = FactoryBot.create(:admin, current_course: student.course)
    login_as(admin, scope: :admin)
    visit course_path(code_review.course)
    click_link 'Grades report'
    expect(page).to have_css '.submission-success'
  end

  it "sorts the table by the student's total score for that code_review", :stub_mailgun do
    student = FactoryBot.create(:student, :with_course)
    better_student = FactoryBot.create(:student, course: student.course)
    code_review = FactoryBot.create(:code_review, course: student.course)
    submission = FactoryBot.create(:submission, code_review: code_review, student: student)
    better_submission = FactoryBot.create(:submission, code_review: code_review, student: better_student)
    review = FactoryBot.create(:review, submission: submission)
    better_review = FactoryBot.create(:review, submission: better_submission)
    failing_grade = FactoryBot.create(:failing_grade, review: review, objective: code_review.objectives.first)
    passing_grade = FactoryBot.create(:passing_grade, review: better_review, objective: code_review.objectives.first)
    admin = FactoryBot.create(:admin, current_course: student.course)
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
      student = FactoryBot.create(:student, :with_course, :with_all_documents_signed)
      code_review = FactoryBot.create(:code_review)
      login_as(student, scope: :student)
      visit course_code_review_report_path(student.course, code_review)
      expect(page).to have_content("not authorized")
    end
  end
end
