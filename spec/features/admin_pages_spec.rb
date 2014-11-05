require 'rails_helper'

feature 'Admin signs in' do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'with valid credentials' do
    visit new_admin_session_path
    fill_in 'Email', with: admin.email
    fill_in 'Password', with: 'password'
    click_on 'Sign in'
    expect(page).to have_content 'Signed in'
  end
end
