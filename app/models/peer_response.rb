class PeerResponse < ApplicationRecord
  OPTIONS = [ 'All of the time', 'Most of the time', 'Some of the time', 'None of the time' ].freeze

  belongs_to :peer_evaluation
  belongs_to :peer_question
end
