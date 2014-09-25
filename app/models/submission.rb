class Submission < ActiveRecord::Base
  validates_presence_of :link

  belongs_to :user
  belongs_to :assessment
  has_many :grades
  accepts_nested_attributes_for :grades
end
