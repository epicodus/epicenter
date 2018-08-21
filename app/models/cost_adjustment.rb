class CostAdjustment < ApplicationRecord
  belongs_to :student
  validates :amount, presence: true
  validates :reason, presence: true

  default_scope { order(:created_at) }
end
