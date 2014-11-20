class PaymentMethod < ActiveRecord::Base
  scope :not_verified_first, -> { order(verified: :desc) }

  validates :account_uri, presence: true
  validates :student_id, presence: true

  belongs_to :student
  has_many :payments

  def ensure_primary_method_exists
    student.set_primary_payment_method(self) if !student.primary_payment_method
  end
end
