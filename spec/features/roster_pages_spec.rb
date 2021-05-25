feature "Viewing roster page" do
  scenario 'as a guest' do
    visit roster_path
    expect(page).to have_content 'need to sign in'
  end

  scenario "as a student" do
    student = FactoryBot.create(:student)
    login_as(student, scope: :student)
    visit roster_path
    expect(page).to have_content "need to sign in"
  end

  context "as an admin" do
    let(:student) { FactoryBot.create(:seattle_student, :with_course) }
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }

    before { login_as(admin, scope: :admin) }

    scenario "can view students" do
      travel_to student.course.start_date do
        FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
        visit roster_path
        expect(page).to have_content "students currently signed in"
        expect(page).to have_content student.name
      end
    end

    scenario "can see students in different office" do
    other_office = FactoryBot.create(:portland_office)
    other_student = FactoryBot.create(:portland_student, :with_all_documents_signed, course: FactoryBot.create(:course, office: other_office))
      travel_to other_student.course.start_date do
        FactoryBot.create(:attendance_record, student: other_student, date: Time.zone.now.to_date)
        visit roster_path
        click_link "Portland"
        expect(page).to have_content "students currently signed in (Portland)"
        expect(page).to have_content other_student.name
      end
    end

    scenario "does not show absent students" do
      visit roster_path
      expect(page).to_not have_content student.name
    end

    scenario "does not show signed out students" do
      travel_to student.course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student, date: Time.zone.now.to_date)
        attendance_record.update({ signing_out: true })
        visit roster_path
        expect(page).to_not have_content student.name
      end
    end
  end
end
