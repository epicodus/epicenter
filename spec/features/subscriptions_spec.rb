require 'rails_helper'

feature 'User creates a subscription' do
  before do
    @user = create(:user)
    sign_in @user
    visit new_subscription_path
    fill_in 'Name on account', with: @user.name
  end
  context 'with valid information', js: true do
    before do
      fill_in 'Bank account number', with: '123456789'
      fill_in 'Routing number', with: '321174851'
      click_on 'Add bank account'
    end

    it "shows loading indicator" do
      expect(page).to have_submit_button("loading...")
    end

    it "redirects to success page successful loading" do
      sleep 10
      expect(page).to have_content 'verify the deposits'
    end
  end

  scenario 'with missing account number', js: true do
    fill_in 'Routing number', with: '321174851'
    click_on 'Add bank account'
    within 'div.error' do
      expect(page).to have_content 'Bank account number'
    end
  end

  scenario 'with invalid routing number', js: true do
    fill_in 'Bank account number', with: '123456789'
    fill_in 'Routing number', with: '1234568'
    click_on 'Add bank account'
    within 'div.error' do
      expect(page).to have_content 'Routing number'
    end
  end
end

feature "user confirms bank account" do
  before do
    user = create(:user)
    subscription = create_subscription
    user.subscription = subscription
    sign_in user
    fill_in 'First deposit amount', with: "1"
  end

  scenario "with correct desposit amounts" do
    fill_in 'Second deposit amount', with: "1"
    click_button "Confirm"
    expect(page).to have_content "Your payment"
    expect(page).to have_content "confirmed"
  end

  scenario "with correct desposit amounts" do
    fill_in 'Second deposit amount', with: "2"
    click_button "Confirm"
    expect(page).to have_content "could not be confirmed"
  end
end
