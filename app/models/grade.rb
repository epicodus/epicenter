class Grade < ActiveRecord::Base
  belongs_to :submission
  belongs_to :requirement
  belongs_to :user
  belongs_to :score

  validates_presence_of :score_id
end
