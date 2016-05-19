feature "viewing transcript" do
  context "before class is over" do
    it "doesn't show link to print certificate" do
      student = FactoryGirl.create(:student)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View/print transcript"
    end
  end

  context "after class ends" do
    it "allows student to view their transcript" do
      course = FactoryGirl.create(:past_course)
      student = FactoryGirl.create(:student, course: course)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      click_link "View transcript"
      expect(page).to have_content "Transcript"
      expect(page).to have_content student.name
    end

    it 'shows a breakdown of how they did on each code review', :stub_mailgun do
      course = FactoryGirl.create(:past_course)
      student = FactoryGirl.create(:student, course: course)
      code_review = FactoryGirl.create(:code_review, course: course)
      submission = FactoryGirl.create(:submission, code_review: code_review, student: student)
      FactoryGirl.create(:passing_review, submission: submission)

      login_as(student, scope: :student)
      visit transcript_path
      expect(page).to have_content code_review.title
    end

    it 'shows a summary of their attendance record' do
      course = FactoryGirl.create(:past_course)
      student = FactoryGirl.create(:student, course: course)
      login_as(student, scope: :student)
      visit transcript_path
      expect(page).to have_content "Present 0 days"
    end
  end
end
