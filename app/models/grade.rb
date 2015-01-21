class Grade < ActiveRecord::Base
  belongs_to :review
  belongs_to :requirement
  belongs_to :score

  validates :requirement_id, presence: true
  validates :score_id, presence: true
end
