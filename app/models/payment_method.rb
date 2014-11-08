class PaymentMethod < ActiveRecord::Base
  scope :not_verified_first, -> { order(verified: :desc) }

  validates :account_uri, presence: true
  validates :student_id, presence: true

  belongs_to :student
  has_many :payments
end
