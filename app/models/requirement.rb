class Requirement < ActiveRecord::Base
  validates :content, presence: true

  belongs_to :assessment
  has_many :grades
end
