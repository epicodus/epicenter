class CreditCard < ActiveRecord::Base
  belongs_to :user

  validates :credit_card_uri, presence: true
  validates :user_id, presence: true
end
