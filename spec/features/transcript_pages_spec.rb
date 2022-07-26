feature "viewing transcript & certificate" do
  context "before first class is over" do
    it "doesn't show transcript to admin" do
      student = FactoryBot.create(:student, :with_course)
      admin = FactoryBot.create(:admin, current_course: student.course)
      login_as(admin, scope: :admin)
      visit student_courses_path(student)
      expect(page).to have_content "Transcript not yet available."
      visit student_transcript_path(student)
      expect(page).to have_content "Transcript not yet available."
    end

    it "doesn't show transcript to student" do
      student = FactoryBot.create(:student, :with_course)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View transcript"
      visit transcript_path
      expect(page).to have_content "Transcript will be available"
    end

    it "doesn't show certificate" do
      student = FactoryBot.create(:student, :with_course)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View certificate of completion"
      visit certificate_path
      expect(page).to have_content "Certificate not yet available."
    end
  end

  context "after completed 1 class" do
    it "allows admin to view student transcript" do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      admin = FactoryBot.create(:admin, current_course: course)
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

    it 'lists Web and Mobile Development for students not in data engineering cohort' do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      click_link "View transcript"
      expect(page).to have_content "Web and Mobile Development"
    end

    it 'lists Data Engineering for students not in data engineering cohort' do
      cohort = FactoryBot.create(:cohort, description: 'Data Engineering')
      cohort.courses << FactoryBot.create(:past_course)
      cohort.courses << FactoryBot.create(:internship_course)
      student = FactoryBot.create(:student, courses: cohort.courses)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      click_link "View transcript"
      expect(page).to have_content "Data Engineering"
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
      course = FactoryBot.create(:past_course, internship_course: true)
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

    # temporarily disabled until we add that feature back in
    xit 'lists completed reflections in a separate section', :stub_mailgun do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      journal = FactoryBot.create(:code_review, course: course, journal: true)
      submission = FactoryBot.create(:submission, code_review: journal, student: student, journal: 'test entry')
      FactoryBot.create(:passing_review, submission: submission)

      login_as(student, scope: :student)
      visit transcript_path
      section = find(:css, '#transcript-journal')
      expect(section).to have_content journal.title
    end

    it 'shows meets attendance requirement message when over 90%' do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      pair = FactoryBot.create(:student, course: course)
      course.class_days.each do |day|
        FactoryBot.create(:attendance_record, student: student, date: day, left_early: false, tardy: false, pair_ids: [pair.id])
      end
      login_as(student, scope: :student)
      visit transcript_path
      expect(page).to have_content "Epicodus requires students to attend class at least 90% of the time. This student met that requirement."
    end

    it 'does not show meets attendance requirement message when under 90%' do
      course = FactoryBot.create(:past_course)
      student = FactoryBot.create(:student, course: course)
      login_as(student, scope: :student)
      visit transcript_path
      expect(page).to_not have_content "Epicodus requires students to attend class at least 90% of the time. This student met that requirement."
    end

    it 'does not show attendance for students enrolled in only online course' do
      course = FactoryBot.create(:past_course, office: FactoryBot.create(:online_office))
      student = FactoryBot.create(:student, course: course)
      travel_to course.start_date - 1.week do
        login_as(student, scope: :student)
        visit transcript_path
        expect(page).to_not have_content "Attendance"
      end
    end
  end
end
