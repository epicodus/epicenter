class Grade < ActiveRecord::Base
  belongs_to :review
  belongs_to :objective
  belongs_to :score

  validates :objective_id, presence: true
  validates :score_id, presence: true
end
