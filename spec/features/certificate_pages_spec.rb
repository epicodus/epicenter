feature "print completion certificate" do
  context "before class is over" do
    it "doesn't show link to print certificate" do
      student = FactoryGirl.create(:student)
      login_as(student, scope: :student)
      visit edit_student_registration_path
      expect(page).to_not have_link "View your certificate of completion"
    end
    it "doesn't show certificate even if student directly enters URL" do
      student = FactoryGirl.create(:student)
      login_as(student, scope: :student)
      visit certificate_path
      expect(page).to_not have_content "Epicodus Certificate of Completion"
    end
  end

  context "after class ends" do
    let(:course) { FactoryGirl.create(:course) }
    let(:internship_course) { FactoryGirl.create(:internship_course) }
    let(:student) { FactoryGirl.create(:student, courses: [course, internship_course]) }
    let(:code_review) { FactoryGirl.create(:code_review, course: course) }
    let(:submission) { FactoryGirl.create(:submission, code_review: code_review, student: student) }

    context "failing code review" do
      it "doesn't show link to print certificate", :stub_mailgun do
        FactoryGirl.create(:failing_review, submission: submission)
        travel_to internship_course.end_date + 1.day do
          login_as(student, scope: :student)
          visit edit_student_registration_path
          expect(page).to_not have_content "View certificate of completion."
        end
      end

      it "doesn't show certificate even if student directly enters URL", :stub_mailgun do
        FactoryGirl.create(:failing_review, submission: submission)
        travel_to internship_course.end_date + 1.day do
          login_as(student, scope: :student)
          visit certificate_path
          expect(page).to have_content "Certificate not yet available."
        end
      end
    end

    context "all code reviews passing" do
      it "allows student to print certificate", :stub_mailgun do
        FactoryGirl.create(:passing_review, submission: submission)
        travel_to internship_course.end_date + 1.day do
          login_as(student, scope: :student)
          visit edit_student_registration_path
          click_link "View certificate of completion"
          expect(page).to have_content "Epicodus Certificate of Completion"
          expect(page).to have_content student.name
        end
      end
    end
  end
end
