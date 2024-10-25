describe PeerEvaluation do
  it { should belong_to(:evaluator).class_name('Student') }
  it { should belong_to(:evaluatee).class_name('Student') }
  it { should have_many(:peer_responses) }
end
