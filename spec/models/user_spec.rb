describe User do
  require 'devise_two_factor/spec_helpers'

  it_behaves_like "two_factor_authenticatable"

  it { should validate_presence_of :name }

  describe '#authenticate_with_github' do
    it 'updates the user github_uid attribute when logging in via GitHub the first time' do
      student = FactoryBot.create(:student)
      student.authenticate_with_github('12345')
      expect(student.github_uid).to eq '12345'
    end

    it 'returns true if a user has previously logged in via GitHub' do
      student = FactoryBot.create(:student, github_uid: '12345')
      expect(student.authenticate_with_github('12345')).to eq true
    end
  end
end
