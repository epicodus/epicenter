require 'rails_helper'

feature 'creating an attendance record' do

  scenario 'correctly' do
    FactoryGirl.create(:user)
    visit '/attendance'
    click_button("I'm here")
    expect(page).to have_content "Welcome"
  end

  scenario 'after having already created one today' do
    user = FactoryGirl.create(:user)
    AttendanceRecord.create(user: user)
    visit '/attendance'
    expect(page).not_to have_content "I'm here"
  end
end

feature 'destroying an attendance record' do

  scenario 'after accidentally creating one' do
    FactoryGirl.create(:user)
    visit '/attendance'
    click_button("I'm here")
    click_link("Not you?")
    expect(page).to have_content 'Attendance record has been deleted'
  end
end
