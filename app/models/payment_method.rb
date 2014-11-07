class PaymentMethod < ActiveRecord::Base
  validates :account_uri, presence: true
  validates :student_id, presence: true

  belongs_to :student
  has_many :payments
end
