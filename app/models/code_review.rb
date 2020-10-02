class CodeReview < ApplicationRecord
  default_scope { order(:number) }

  validates :title, presence: true
  validates :course, presence: true
  validate :presence_of_objectives, unless: ->(cr) { cr.github_path.present? }

  has_many :objectives
  has_many :submissions
  belongs_to :course

  accepts_nested_attributes_for :objectives, reject_if: :attributes_blank?, allow_destroy: true

  before_validation :update_from_github, if: ->(cr) { cr.github_path.present? }
  before_create :set_number
  before_destroy :check_for_submissions

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

  def visible?(student)
    if visible_date.blank?
      true
    elsif expectations_met_by?(student)
      false
    else
      zone = ActiveSupport::TimeZone[course.office.time_zone]
      current_time = Time.now.in_time_zone(zone)
      current_time >= visible_date
    end
  end

  def course_description_and_code_review_title
    "#{course.description} - #{course.office.name} - #{title}"
  end

private

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
end
