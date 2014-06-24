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
  context 'with valid information', js: true do
    before do
      visit new_user_registration_path
      fill_in 'Email', with: 'example_user@example.com'
      fill_in 'Password', with: 'password'
      fill_in 'Password confirmation', with: 'password'
      fill_in 'Name', with: 'Ryan Larson'
      fill_in 'Bank account number', with: '123456789'
      fill_in 'Routing number', with: '321174851'
      click_on 'Sign up'
    end

    it "shows a loading page" do
      expect(page).to have_submit_button("loading")
    end

    it "redirects to success page successful loading" do
      sleep 8
      expect(page).to have_content 'verify your account'
    end
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

feature "User signs in" do
  subject { page }

  context "with unverified account" do
    before do
      user = create(:user)
      sign_in user
    end

    it { should have_content "First deposit amount" }
  end

  context "with verified account" do
    before do
      user = create(:user_with_verified_subscription)
      sign_in user
    end

    it { should have_content "last payment" }
  end
end
