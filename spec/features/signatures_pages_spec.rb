feature 'document signing for new students' do
  let(:student) { FactoryGirl.create(:student) }

  before :each do
    login_as(student, scope: :student)
  end

  xscenario 'signing the code of conduct', js: true do
    visit new_code_of_conduct_path
    within_frame 'hsEmbeddedFrame' do
      create_hello_sign_signature
      expect(page).to have_content 'Sign to accept the Epicodus Code of Conduct'
    end
  end

  xscenario 'signing the refund policy', js: true do
    visit new_refund_policy_path
    within_frame 'hsEmbeddedFrame' do
      create_hello_sign_signature
      expect(page).to have_content 'Sign to accept the Epicodus Refund Policy'
    end
  end

  xscenario 'signing the Seattle complaint disclosure policy', js: true do
    visit new_complaint_disclosure_path
    within_frame 'hsEmbeddedFrame' do
      create_hello_sign_signature
      expect(page).to have_content 'Sign to accept the Seattle Complaint Disclosure'
    end
  end

  xscenario 'signing the enrollment agreement', js: true do
    visit new_enrollment_agreement_path
    within_frame 'hsEmbeddedFrame' do
      create_hello_sign_signature
      expect(page).to have_content 'Sign to accept the Epicodus Enrollment Agreement'
    end
  end
end
