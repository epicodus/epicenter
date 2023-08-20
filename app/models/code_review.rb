class CodeReview < ApplicationRecord
  default_scope { order(:number) }
  scope :current_cohort_code_reviews, -> { where(course: Course.current_cohort_courses) }

  validates :title, presence: true
  validates :course, presence: true
  validate :presence_of_objectives, unless: ->(cr) { cr.github_path.present? || cr.journal? }

  has_many :objectives
  has_many :submissions
  has_many :special_permissions
  has_many :code_review_visibilities, dependent: :destroy
  belongs_to :course

  accepts_nested_attributes_for :objectives, reject_if: :attributes_blank?, allow_destroy: true

  before_validation :update_from_github, if: ->(cr) { cr.github_path.present? }
  before_create :normalize_title
  before_create :set_number, if: ->(cr) { cr.number.nil? }
  before_destroy :check_for_submissions
  after_create :create_code_review_visibilities

  def total_points_available
    objectives.length * 3
  end

  def submission_for(student)
    submissions.find_by(student: student)
  end

  def expectations_met_by?(student)
    submission_for(student).try(:meets_expectations?)
  end

  def latest_total_score_for(student)
    if submission_for(student).try(:has_been_reviewed?)
      objectives.inject(0) { |sum, objective| sum += objective.score_for(student) }
    else
      0
    end
  end

  def status(student)
    review_status = submission_for(student).try(:review_status)
    if review_status == 'fail'
      'Did not meet requirements'
    elsif review_status == 'pass'
      'Met requirements'
    else
      'Pending'
    end
  end

  def export_submissions(filename, all)
    submissions = all ? self.submissions.includes(:student) : self.submissions.needing_review.includes(:student)
    File.open(filename, 'w') do |file|
      submissions.each do |submission|
        file.puts submission.student.name.parameterize + " " + submission.link if submission.student
      end
    end
  end

  def duplicate_code_review(course)
    copy_code_review = self.deep_clone include: :objectives
    copy_code_review.course = course
    if self.due_date
      if course.parttime?
        copy_code_review.visible_date = Date.today.beginning_of_week + 3.days + 17.hours
        copy_code_review.due_date = Date.today.beginning_of_week + 10.days + 17.hours
      else
        copy_code_review.visible_date = Date.today.beginning_of_week + 4.days + 8.hours
        copy_code_review.due_date = Date.today.beginning_of_week + 4.days + 17.hours
      end
    end
    copy_code_review
  end

  def code_review_visibility_for(student)
    code_review_visibilities.find_by(student: student)
  end

  def visible?(student)
    code_review_visibility_for(student).try(:visible?)
  end

  def past_due?(student)
    code_review_visibility_for(student).try(:past_due?)
  end

private

  def failing_submission?(student)
    submission_for(student).try(:review_status) == 'fail'
  end

  def check_for_submissions
    if submissions.any?
      errors.add(:base, 'Cannot delete a code review with existing submissions.')
      throw :abort
    end
  end

  def set_number
    self.number = course.code_reviews.pluck(:number).last.to_i + 1
  end

  def presence_of_objectives
    if objectives.size < 1
      errors.add(:objectives, 'must be present.')
    end
  end

  def attributes_blank?(attributes)
    attributes['content'].blank?
  end

  def update_from_github
    response = Github.get_content(github_path)
    if response[:error]
      errors.add(:base, 'Unable to pull code review from Github')
      throw(:abort)
    else
      self.content = response[:content]
    end
  end

  def normalize_title
    self.title = title.strip
  end

  def create_code_review_visibilities
    course.students.find_each do |student|
      code_review_visibilities.create(student: student)
    end
  end
end
