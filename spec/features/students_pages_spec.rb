feature 'Student signs up via invitation' do

  let(:student) { FactoryGirl.create(:student) }

  scenario 'with valid information', js: true do
    student.invite!
    visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
    fill_in 'Name', with: 'Ryan Larson'
    select student.plan.name, from: 'student_plan_id'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_on 'Submit'
    expect(page).to have_content 'Your password was set successfully. You are now signed in.'
  end

  scenario 'with missing information', js: true do
    student.invite!
    visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
    fill_in 'Name', with: ''
    select student.plan.name, from: 'student_plan_id'
    click_on 'Submit'
    expect(page).to have_content 'error'
  end
end

feature 'Student cannot invite other students' do

  let (:student) { FactoryGirl.create(:student) }

  scenario 'student visits new_student_invitation path', js: true do
    login_as(student)
    visit new_student_invitation_path
    expect(page).to have_content 'You need to sign in or sign up before continuing'
  end
end


feature "Student signs in while class is not in session" do

  let(:future_cohort) { FactoryGirl.create(:future_cohort) }
  let(:student) { FactoryGirl.create(:student, cohort: future_cohort) }

  context "before adding a payment method" do
    it "takes them to the page to choose payment method" do
      FactoryGirl.create(:completed_code_of_conduct, student: student)
      FactoryGirl.create(:completed_refund_policy, student: student)
      FactoryGirl.create(:completed_enrollment_agreement, student: student)
      FactoryGirl.create(:completed_promissory_note, student: student)
      sign_in(student)
      visit new_payment_method_path
      expect(page).to have_content "How would you like to make payments"
    end
  end

  context "after entering bank account info but before verifying" do
    it "takes them to the payment methods page", :vcr do
      bank_account = FactoryGirl.create(:bank_account, student: student)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "Your payment methods"
      expect(page).to have_link "Verify Account"
    end
  end

  context "after verifying their bank account", :vcr do
    it "shows them their payment history" do
      verified_bank_account = FactoryGirl.create(:verified_bank_account, student: student)
      sign_in(student)
      visit payments_path
      expect(page).to have_content "Your payments"
    end
  end

  context "after adding a credit card", :vcr do
    it "shows them their payment history" do
      credit_card = FactoryGirl.create(:credit_card, student: student)
      sign_in(student)
      visit payments_path
      expect(page).to have_content "Your payments"
    end
  end
end

feature "Student visits homepage after logged in" do
  let(:student) { FactoryGirl.create(:student) }

  it "takes them to the correct path" do
    sign_in(student)
    visit root_path
    expect(current_path).to_not eq root_path
  end
end

feature "Student signs in while class is in session" do
  let(:student) { FactoryGirl.create(:student) }

  it "takes them to the code reviews page" do
    sign_in(student)
    expect(current_path).to eq cohort_code_reviews_path(student.cohort)
    expect(page).to have_content "Code Reviews"
  end
end

feature 'Guest not signed in' do
  subject { page }

  context 'visits new subscrition path' do
    before { visit new_bank_account_path }
    it { should have_content 'You need to sign in'}
  end

  context 'visits edit verification path' do
    before { visit edit_bank_account_path(1) }
    it { should have_content 'You need to sign in' }
  end

  context 'visits payments path' do
    let(:student) { FactoryGirl.create(:student) }
    before { visit payments_path }
    it { should have_content 'You need to sign in' }
  end
end
