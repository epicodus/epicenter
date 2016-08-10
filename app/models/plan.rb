class Plan < ActiveRecord::Base
  scope :active, -> { where(archived: nil) }

  has_many :students
  validates :name, presence: true
  validates :upfront_amount, presence: true
end
