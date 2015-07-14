class Plan < ActiveRecord::Base
  has_many :students
  validates :name, presence: true
  validates :recurring_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :upfront_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def recurring?
    recurring_amount > 0 
  end
end
