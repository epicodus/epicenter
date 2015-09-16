describe 'student list' do
  it 'should list students in alphabetical order' do
    admin = FactoryGirl.create(:admin)
    student = FactoryGirl.create(:student, cohort: admin.current_cohort, name: 'zelda')
    another_student = FactoryGirl.create(:student, cohort: admin.current_cohort, name: 'annie')
    login_as(admin, scope: :admin)
    visit attendance_path
    within first("div.student") do
      expect(page).to have_content 'annie'
    end
  end
end

feature 'creating an attendance record' do
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'correctly' do
    FactoryGirl.create(:student, cohort: admin.current_cohort)
    visit attendance_path
    click_button("I'm soloing")
    expect(page).to have_content "Welcome"
  end

  scenario 'after having already created one today' do
    FactoryGirl.create(:attendance_record)
    visit attendance_path
    expect(page).not_to have_content "I'm soloing"
  end
end

feature 'destroying an attendance record' do
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'after accidentally creating one' do
    FactoryGirl.create(:student, cohort: admin.current_cohort)
    visit attendance_path
    click_button("I'm soloing")
    click_link("Wrong student?")
    expect(page).to have_content 'Attendance record has been deleted'
  end
end

feature 'only allow admins to view attendance sign-in page' do
  let!(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

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

feature 'pair log in for attendance page' do
  let(:cohort) { FactoryGirl.create(:cohort) }
  let(:admin) { FactoryGirl.create(:admin, current_cohort: cohort) }
  let!(:student_1) { FactoryGirl.create(:user_with_all_documents_signed, cohort: cohort) }
  let!(:student_2) { FactoryGirl.create(:user_with_all_documents_signed, cohort: cohort) }
  before { login_as(admin, scope: :admin) }

  scenario 'students successfully log in as a pair' do
    visit attendance_path
    select student_1.name, from: 'pair_1'
    select student_2.name, from: 'pair_2'
    click_button 'Pair log in'
    expect(page).to have_content "Welcome #{student_1.name} and #{student_2.name}."
  end

  scenario 'students try to pair with same student twice' do
    visit attendance_path
    select student_1.name, from: 'pair_1'
    select student_1.name, from: 'pair_2'
    click_button 'Pair log in'
    expect(page).to have_content "Something went wrong: Pair cannot be yourself."
  end
end

feature 'student logging out on attendance page' do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  before { login_as(admin, scope: :admin) }

  scenario 'student successfully logs out' do
    visit attendance_path
    click_button("I'm soloing")
    click_button("I'm leaving")
    expect(page).to have_content "#{student.name} successfully updated."
  end
end
