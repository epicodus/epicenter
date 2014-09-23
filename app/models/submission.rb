class Submission < ActiveRecord::Base
  validates_presence_of :link

  belongs_to :user
  belongs_to :assessment
end
