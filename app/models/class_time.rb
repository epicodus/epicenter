class ClassTime < ApplicationRecord
  has_and_belongs_to_many :courses

  validates :wday, :start_time, :end_time, presence: true
end
