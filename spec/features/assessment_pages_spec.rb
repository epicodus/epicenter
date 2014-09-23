require 'rails_helper'

feature 'User creates new assessment' do
  before do
    visit new_assessment_path
  end

  scenario 'with valid form', js: true do
    fill_in 'Title', with: 'example title'
    fill_in 'Section', with: 'example section'
    fill_in 'Url', with: 'www.someurl.com'
    click_on 'Submit'
    expect(page).to have_content 'Assessment added!'
  end

  scenario 'with invalid form', js: true do
    fill_in 'Title', with: 'example title'
    fill_in 'Section', with: ''
    fill_in 'Url', with: 'www.someurl.com'
    click_on 'Submit'
    expect(page).to have_content 'Please correct these problems:'
  end
end

feature 'User edits assessment' do
  before do
    assessment = FactoryGirl.create(:assessment)
    visit assessment_path(assessment)
    click_link "Edit Assessment"
  end

  scenario 'with valid form', js: true do
    fill_in 'Title', with: 'example title'
    click_on 'Submit'
    expect(page).to have_content 'Assessment updated!'
  end

  scenario 'with invalid form', js: true do
    fill_in 'Title', with: ''
    click_on 'Submit'
    expect(page).to have_content 'Please correct these problems:'
  end
end
