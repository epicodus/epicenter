class Review < ActiveRecord::Base
  belongs_to :submission
  belongs_to :user
  has_many :grades

  validates :note, presence: true
end
