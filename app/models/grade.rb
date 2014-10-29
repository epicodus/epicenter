class Grade < ActiveRecord::Base
  belongs_to :review
  belongs_to :requirement
  belongs_to :user
  belongs_to :score

  validates_presence_of :score_id
  validates_presence_of :requirement_id
end
