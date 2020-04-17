class PeerResponse < ApplicationRecord
  OPTIONS = [ { text: 'All of the time', value: 3 }, { text: 'Most of the time', value: 2 }, { text: 'Some of the time', value: 1 }, { text: 'None of the time', value: 0 } ].freeze

  belongs_to :peer_evaluation
  belongs_to :peer_question
end
