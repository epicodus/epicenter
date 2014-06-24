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
    user = build(:user)
    visit new_user_registration_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'Password confirmation', with: user.password_confirmation
    fill_in 'Name', with: user.name
    fill_in 'Bank account number', with: '123456789'
    fill_in 'Routing number', with: '321174851'
    click_on 'Sign up'
    expect(page).to have_content 'verify your account'
  end

  scenario 'with missing account number', js: true do
    visit new_user_registration_path
    fill_in 'Email', with: 'user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    fill_in 'Name', with: 'Jeremiah Johann'
    fill_in 'Routing number', with: '321174851'
    click_on 'Sign up'
    within 'div.error' do
      expect(page).to have_content 'Bank account number'
    end
  end

  scenario 'with invalid routing number', js: true do
    visit new_user_registration_path
    fill_in 'Email', with: 'user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    fill_in 'Name', with: 'Jeremiah Johann'
    fill_in 'Bank account number', with: '123456789'
    fill_in 'Routing number', with: '1234568'
    click_on 'Sign up'
    within 'div.error' do
      expect(page).to have_content 'Routing number'
    end
  end
end


