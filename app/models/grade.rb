class Grade < ActiveRecord::Base
  belongs_to :submission
  belongs_to :requirement
  validates_presence_of :score
end
