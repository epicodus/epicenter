class Checkin < ApplicationRecord
  belongs_to :student, class_name: 'User'
  belongs_to :admin, class_name: 'User'

  scope :this_week, -> { where('created_at > ?', Date.today.beginning_of_week - 2.days) }
end
