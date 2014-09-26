class Grade < ActiveRecord::Base
  belongs_to :submission
  belongs_to :requirement
  belongs_to :user

  validates_presence_of :score
end
