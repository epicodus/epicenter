feature "viewing transcript & certificate" do
  context "before first class is over" do
    it "doesn't show transcript to admin" do
      admin = FactoryBot.create(:admin)
      student = FactoryBot.create(:student)
      login_as(admin, scope: :admin)
      visit student_courses_path(student)
      expect(page).to have_content "Transcript not yet available."
      visit student_transcript_path(student)
      expect(page).to have_content "Transcript not yet available."
    end

    it "doesn't show transcript to student" do
      student = FactoryBot.create(:student)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View transcript"
      visit transcript_path
      expect(page).to have_content "Transcript will be available"
    end

    it "doesn't show certificate" do
      student = FactoryBot.create(:student)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View certificate of completion"
      visit certificate_path
      expect(page).to have_content "Certificate not yet available."
    end
  end

  context "after completed 1 class" do
    it "allows admin to view student transcript" do
      admin = FactoryBot.create(:admin)
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      login_as(admin, scope: :admin)
      visit student_courses_path(student)
      click_link "View transcript"
      expect(page).to have_content "Transcript"
      expect(page).to have_content student.name
    end

    it "allows student to view their transcript" do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      click_link "View transcript"
      expect(page).to have_content "Transcript"
      expect(page).to have_content student.name
    end

    it "doesn't show certificate" do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View certificate of completion"
      visit certificate_path
      expect(page).to have_content "Certificate not yet available."
    end
  end

  context "after internship class ends" do
    it "allows student to view their transcript" do
      internship_language = FactoryBot.create(:internship_language)
      course = FactoryBot.create(:past_course, language: internship_language)
      student = FactoryBot.create(:student, course: course)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      click_link "View transcript"
      expect(page).to have_content "Transcript"
      expect(page).to have_content student.name
    end

    it "allows student to view their certificate if passed all code reviews", :stub_mailgun do
      internship_language = FactoryBot.create(:internship_language)
      course = FactoryBot.create(:past_course, language: internship_language)
      student = FactoryBot.create(:student, course: course)
      code_review = FactoryBot.create(:code_review, course: course)
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:passing_review, submission: submission)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      click_link "View certificate of completion"
      expect(page).to have_content "Epicodus Certificate of Completion"
      expect(page).to have_content student.name
    end

    it "doesn't show certificate if student has any failing code reviews", :stub_mailgun do
      internship_language = FactoryBot.create(:internship_language)
      course = FactoryBot.create(:past_course, language: internship_language)
      student = FactoryBot.create(:student, course: course)
      code_review = FactoryBot.create(:code_review, course: course)
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:failing_review, submission: submission)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View certificate of completion"
      visit certificate_path
      expect(page).to have_content "Certificate not yet available."
    end

    it 'shows a breakdown of how they did on each code review', :stub_mailgun do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      code_review = FactoryBot.create(:code_review, course: course)
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:passing_review, submission: submission)

      login_as(student, scope: :student)
      visit transcript_path
      expect(page).to have_content code_review.title
    end

    it 'shows a summary of their attendance record' do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      login_as(student, scope: :student)
      visit transcript_path
      expect(page).to have_content "Present 0 days"
    end
  end
end
