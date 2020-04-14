describe PeerResponse do
  it { should belong_to(:peer_evaluation) }
  it { should belong_to(:peer_question) }
end
