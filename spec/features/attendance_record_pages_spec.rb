require 'rails_helper'

feature 'creating an attencance record' do
  before do
    5.times { FactoryGirl.create(:user) }
  end

  scenario 'correctly' do
    visit '/attendance'
    first('form').click_button("I'm here")
    expect(page).to have_content "Welcome"
  end

  scenario 'after having already created one today' do
    user = User.first
    AttendanceRecord.create(user: user)
    visit '/attendance'
    first('form').click_button("I'm here")
    expect(page).to have_content "You have already signed in today"
  end
end
