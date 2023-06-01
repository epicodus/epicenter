describe Track do
  it { should have_and_belong_to_many(:languages) }
  it { should have_many(:courses) }
  it { should have_many(:cohorts) }

  describe 'active scope' do
    it 'returns all tracks that are not archived' do
      track = FactoryBot.create(:track, description: 'Ruby/Rails')
      archived_track = FactoryBot.create(:track, archived: true)
      expect(Track.active).to eq [track]
    end
  end

  describe '.fulltime' do
    it 'returns all full-time tracks' do
      track = FactoryBot.create(:track, description: 'Ruby/Rails')
      parttime_track = FactoryBot.create(:part_time_track)
      expect(Track.fulltime).to eq [track]
    end
  end

end
