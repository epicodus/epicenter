feature 'Viewing recurring payments option page' do
  scenario 'as a guest' do
    visit recurring_payments_option_index_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student' do
    student = FactoryGirl.create(:student)
    login_as(student, scope: :student)
    visit recurring_payments_option_index_path
    expect(page).to have_content 'Recurring payments'
  end
end
