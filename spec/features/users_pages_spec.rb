require 'rails_helper'

feature 'User signs up' do
  scenario 'with valid information', js: true do
    visit new_user_registration_path
    fill_in 'Email', with: 'example_user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    fill_in 'Name', with: 'Ryan Larson'
    click_on 'Sign up'
    expect(page).to have_content 'bank account information'
  end

  scenario 'with missing information', js: true do
    visit new_user_registration_path
    fill_in 'Email', with: 'user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'error'
  end
end

feature "User signs in" do
  subject { page }

  context "with unverified account" do
    before do
      user = create(:user_with_subscription)
      sign_in user
    end

    it { should have_content "First deposit amount" }
  end

  context "with verified account" do
    before do
      user = create(:user_with_verified_subscription)
      sign_in user
    end

    it { should have_content "Your payments" }
  end
end
