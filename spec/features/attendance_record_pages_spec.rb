feature 'creating an attendance record' do
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'correctly' do
    FactoryGirl.create(:student, cohort: admin.current_cohort)
    visit attendance_path
    click_button("I'm here")
    expect(page).to have_content "Welcome"
  end

  scenario 'after having already created one today' do
    FactoryGirl.create(:attendance_record)
    visit attendance_path
    expect(page).not_to have_content "I'm here"
  end
end

feature 'destroying an attendance record' do
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'after accidentally creating one' do
    FactoryGirl.create(:student, cohort: admin.current_cohort)
    visit attendance_path
    click_button("I'm here")
    click_link("Not you?")
    expect(page).to have_content 'Attendance record has been deleted'
  end
end

feature 'only allow admins to view attendance sign-in page' do
  let!(:student) { FactoryGirl.create(:student) }

  scenario "guest tries to view sign-in page" do
    visit attendance_path
    expect(page).to have_content "You need to sign in."
  end

  scenario "student tries to view sign-in page" do
    login_as(student, scope: :student)
    visit attendance_path
    expect(page).to have_content "You are not authorized to access this page."
  end
end
