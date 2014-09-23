class Submission < ActiveRecord::Base
  validates_presence_of :link
  validates_uniqueness_of :assessment_id, scope: :user_id

  belongs_to :user
  belongs_to :assessment
end
