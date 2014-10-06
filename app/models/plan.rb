class Plan < ActiveRecord::Base
  has_many :users
  validates :recurring_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :upfront_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
