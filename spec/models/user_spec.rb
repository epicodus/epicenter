require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should validate_presence_of :plan_id }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should belong_to :plan }
  it { should have_many :attendance_records }

  describe '#signed_in_today?' do
    let(:user) { FactoryGirl.create(:user) }

    it 'is false if the user has not signed in today' do
      expect(user.signed_in_today?).to eq false
    end
    
    it 'is true if the user has already signed in today' do
      attendance_record = FactoryGirl.create(:attendance_record, user: user)
      expect(user.signed_in_today?).to eq true
    end
  end
end
