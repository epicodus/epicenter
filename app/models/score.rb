class Score < ActiveRecord::Base
  validates :value, presence: true
  validates :description, presence: true
end
