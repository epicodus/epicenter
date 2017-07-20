feature "Viewing roster page" do
  scenario 'as a guest' do
    visit roster_path
    expect(page).to have_content 'need to sign in'
  end

  scenario "as a student" do
    student = FactoryGirl.create(:student)
    login_as(student, scope: :student)
    visit roster_path
    expect(page).to have_content "need to sign in"
  end

  context "as an admin" do
    let(:student) { FactoryGirl.create(:seattle_student) }
    let(:admin) { FactoryGirl.create(:admin, current_course: student.course) }

    before { login_as(admin, scope: :admin) }

    scenario "can view students" do
      FactoryGirl.create(:attendance_record, student: student, date: Time.zone.now.to_date)
      visit roster_path
      expect(page).to have_content "students currently signed in"
      expect(page).to have_content student.name
    end

    scenario "can see students in different office" do
      other_student = FactoryGirl.create(:portland_student_with_all_documents_signed)
      FactoryGirl.create(:attendance_record, student: other_student, date: Time.zone.now.to_date)
      visit roster_path
      click_link "Portland"
      expect(page).to have_content "students currently signed in (Portland)"
      expect(page).to have_content other_student.name
    end

    scenario "does not show absent students" do
      visit roster_path
      expect(page).to_not have_content student.name
    end

    scenario "does not show signed out students" do
      attendance_record = FactoryGirl.create(:attendance_record, student: student, date: Time.zone.now.to_date)
      attendance_record.update({ signing_out: true })
      visit roster_path
      expect(page).to_not have_content student.name
    end
  end
end
