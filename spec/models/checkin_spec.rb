describe Checkin do
  it { should belong_to(:admin) }
  it { should belong_to(:student) }

  describe 'checkins during a specific week' do
    let(:student) { FactoryBot.create(:student) }
    let(:admin) { FactoryBot.create(:admin) }

    before do
      2.times { FactoryBot.create(:checkin, student: student, admin: admin, created_at: 1.week.ago) }
      3.times { FactoryBot.create(:checkin, student: student, admin: admin, created_at: Date.today) }
    end

    it 'returns the count of check-ins from this week' do
      expect(Checkin.week.count).to eq(3)
    end

    it 'returns the count of check-ins from last week' do
      expect(Checkin.week(1.week.ago).count).to eq(2)
    end
  end
end
