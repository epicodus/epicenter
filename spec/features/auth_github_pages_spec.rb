require 'rails_helper'

feature 'User signs up with Github' do
  before do
    visit new_user_registration_path
  end

  scenario 'with valid github account', js: true do
    mock_auth_hash
    click_link 'Sign in with Github'
    expect(page).to have_content 'bank account information'
  end

  scenario 'with invalid github credentials', js: true do
    mock_auth_hash_fail
    click_link 'Sign in with Github'
    expect(page).to have_content 'Could not authenticate you from GitHub'
  end
end
