require 'rails_helper'

feature 'Home page' do
  subject { page }
  before(:each) { visit root_path }

  it { should have_link 'Start Making Payments' }
  it { should have_link 'Sign-in'}
end

describe 'Start making payments link' do
  it "navigates to sign up page" do
    visit root_path
    click_on 'Start Making Payments'
    expect(page).to have_content 'Sign up'
  end
end


feature 'User signs up' do
  scenario 'with valid information' do
    visit new_user_registration_path
    fill_in 'First name', with: 'Jeremiah'
    fill_in 'Last name', with: 'Johann'
    fill_in 'Email', with: 'user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'Add bank account'
  end
end
