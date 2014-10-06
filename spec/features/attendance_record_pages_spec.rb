require 'rails_helper'

feature 'creating an attencance record' do
  before { @user = FactoryGirl.create(:user) }

  scenario 'correctly' do
    visit '/attendance'
    click_button("I'm here")
    expect(page).to have_content "Welcome"
  end

  scenario 'after having already created one today' do
    AttendanceRecord.create(user: @user)
    visit '/attendance'
    expect(page).not_to have_content "I'm here"
  end
end

feature 'destroying an attendance record' do
  before { @user = FactoryGirl.create(:user) }

  scenario 'after accidentally creating one' do
    visit '/attendance'
    click_button("I'm here")
    click_link("Not you?")
    expect(page).to have_content 'Attendance record has been deleted'
  end
end
