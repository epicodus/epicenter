class PeerQuestion < ApplicationRecord
  has_many :peer_responses

  validates :content, presence: true
  validates :category, presence: true
  validates :input_type, presence: true

  default_scope { order(:number) }
  before_create :set_number

private
  def set_number
    self.number = PeerQuestion.pluck(:number).last.to_i + 1
  end
end
