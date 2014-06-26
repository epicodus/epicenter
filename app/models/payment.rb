class Payment < ActiveRecord::Base
  belongs_to :subscription
  validates_presence_of :amount, :subscription_id
end
