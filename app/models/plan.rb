class Plan < ActiveRecord::Base
  belongs_to :user
  validates :recurring_amt, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :upfront_amt, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
