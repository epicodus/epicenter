feature 'Viewing payments option page' do
  scenario 'as a guest' do
    visit new_payment_option_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student' do
    student = FactoryGirl.create(:student)
    login_as(student, scope: :student)
    visit new_payment_option_path
    expect(page).to have_content 'What payment option'
  end
end
