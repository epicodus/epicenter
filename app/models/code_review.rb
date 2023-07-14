class CodeReview < ApplicationRecord
  default_scope { order(:number) }

  validates :title, presence: true
  validates :course, presence: true
  validate :presence_of_objectives, unless: ->(cr) { cr.github_path.present? || cr.journal? }

  has_many :objectives
  has_many :submissions
  has_many :special_permissions
  belongs_to :course

  accepts_nested_attributes_for :objectives, reject_if: :attributes_blank?, allow_destroy: true

  before_validation :update_from_github, if: ->(cr) { cr.github_path.present? }
  before_create :normalize_title
  before_create :set_number, if: ->(cr) { cr.number.nil? }
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
    elsif special_permissions.where(student: student).exists?
      true
    else
      zone = ActiveSupport::TimeZone[course.office.time_zone]
      current_time = Time.now.in_time_zone(zone)
      current_time >= visible_date && current_time <= next_past_due_date(student)
    end
  end

  def next_past_due_date(student)
    beginning_of_week = base_date_for_next_past_due_date(student).beginning_of_week(:sunday)
    next_due_date = course.parttime? ? beginning_of_week + 7.days + 9.hours : beginning_of_week + 8.days + 8.hours
    next_due_date <= base_date_for_next_past_due_date(student) ? next_due_date + 1.week : next_due_date
  end

  # hacky way of handling code climate method complexity fail
  def base_date_for_next_past_due_date(student)
    failing_submission?(student) ? submission_for(student).latest_review.created_at : visible_date
  end

  def past_due?(student)
    zone = ActiveSupport::TimeZone[course.office.time_zone]
    current_time = Time.now.in_time_zone(zone)
    current_time > next_past_due_date(student)
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
end
