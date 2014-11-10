feature 'Student signs up' do
  before do
    @plan = FactoryGirl.create :recurring_plan_with_upfront_payment
    @cohort = FactoryGirl.create :future_cohort
    visit new_student_registration_path
    fill_in 'Email', with: 'example_user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
  end

  scenario 'with valid information', js: true do
    fill_in 'Name', with: 'Ryan Larson'
    select @plan.name, from: 'student_plan_id'
    select @cohort.description, from: 'student_cohort_id'
    click_on 'Sign up'
    expect(page).to have_content 'How would you like to make payments'
  end

  scenario 'with missing information', js: true do
    click_on 'Sign up'
    expect(page).to have_content 'error'
  end
end

feature "Student signs in while class is not in session" do

  let(:future_cohort) { FactoryGirl.create(:future_cohort) }
  let(:student) { FactoryGirl.create(:student, cohort: future_cohort) }

  context "before adding a payment method" do
    it "takes them to the page to choose payment method" do
      sign_in(student)
      expect(page).to have_content "How would you like to make payments"
    end
  end

  context "after entering bank account info but before verifying" do
    it "takes them to the payment methods page", :vcr do
      bank_account = FactoryGirl.create(:bank_account, student: student)
      sign_in student
      expect(page).to have_content "Your payment methods"
      expect(page).to have_link "Verify Account"
    end
  end

  context "after verifying their bank account", :vcr do
    it "shows them their payment history" do
      verified_bank_account = FactoryGirl.create(:verified_bank_account, student: student)
      sign_in(student)
      expect(page).to have_content "Your payments"
    end
  end

  context "after adding a credit card", :vcr do
    it "shows them their payment history" do
      credit_card = FactoryGirl.create(:credit_card, student: student)
      sign_in(student)
      expect(page).to have_content "Your payments"
    end
  end
end

feature "Student signs in while class is in session" do
  let(:student) { FactoryGirl.create(:student) }

  it "takes them to the assessments page" do
    sign_in(student)
    expect(current_path).to eq assessments_path
    expect(page).to have_content "Assessments"
  end
end

feature 'Guest not signed in' do
  subject { page }

  context 'visits new subscrition path' do
    before { visit new_bank_account_path }
    it { should have_content 'You need to sign in'}
  end

  context 'visits edit verification path' do
    before { visit edit_bank_account_verification_path(1) }
    it { should have_content 'You need to sign in' }
  end

  context 'visits payments path' do
    let(:student) { FactoryGirl.create(:student) }
    before { visit payments_path }
    it { should have_content 'You need to sign in' }
  end
end
