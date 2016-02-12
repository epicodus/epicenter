class Plan < ActiveRecord::Base
  has_many :students
  validates :name, presence: true
  validates :upfront_amount, presence: true
  validates :total_amount, presence: true
end
