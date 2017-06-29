class Score < ApplicationRecord
  validates :value, presence: true
  validates :description, presence: true
  has_many :grades
end
