class PeerEvaluation < ApplicationRecord
  belongs_to :evaluator, class_name: :Student
  belongs_to :evaluatee, class_name: :Student
  has_many :peer_responses

  accepts_nested_attributes_for :peer_responses, allow_destroy: true
end
