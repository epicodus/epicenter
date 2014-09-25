class Submission < ActiveRecord::Base
  validates_presence_of :link

  belongs_to :user
  belongs_to :assessment
  has_many :grades

  scope :assessed, -> { where(graded: true) }
  scope :unassessed, -> { where(graded: false) }

  accepts_nested_attributes_for :grades

