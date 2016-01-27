class Grade < ActiveRecord::Base
  default_scope { includes(:score) }

  belongs_to :review
  belongs_to :objective
  belongs_to :score

  validates :objective_id, presence: true
  validates :score_id, presence: true
end
