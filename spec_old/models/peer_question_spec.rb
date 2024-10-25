describe PeerQuestion do
  it { should have_many :peer_responses }

  it { should validate_presence_of :content }
  it { should validate_presence_of :category }

  describe '.default_scope' do
    let(:question_2) { FactoryBot.create(:peer_question) }
    let(:question_1) { FactoryBot.create(:peer_question) }

    it 'orders code reviews by their number, ascending' do
      question_1.update_attribute(:number, 1)
      question_2.update_attribute(:number, 2)
      expect(PeerQuestion.all).to eq [question_1, question_2]
    end
  end
end
