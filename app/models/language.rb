class Language < ActiveRecord::Base
  validates :name, presence: true
  validates :level, presence: true

  has_many :courses
end
