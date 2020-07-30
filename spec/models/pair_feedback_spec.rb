describe PairFeedback do
  it { should belong_to(:student) }
  it { should belong_to(:pair).class_name('Student') }
  it { should validate_presence_of :q1_response }
  it { should validate_presence_of :q2_response }
  it { should validate_presence_of :q3_response }

  it 'returns total score' do
    pair_feedback = FactoryBot.create(:pair_feedback)
    expect(pair_feedback.score).to eq pair_feedback.q1_response + pair_feedback.q2_response + pair_feedback.q3_response
  end
end
