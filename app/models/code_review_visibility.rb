class CodeReviewVisibility < ApplicationRecord
  belongs_to :student
  belongs_to :code_review
  validates :student_id, uniqueness: { scope: :code_review_id }

  before_create :set_initial_visibility
  after_create :set_visible_end
  after_update :set_visible_end, if: :saved_change_to_visible_start?

  def visible?
    if always_visible
      true
    elsif code_review.expectations_met_by?(student)
      false
    elsif special_permission
      true
    else
      current_time >= visible_start && current_time <= visible_end
    end
  end

  def past_due?
    !always_visible && current_time > visible_end
  end

private

  def set_initial_visibility
    if code_review.visible_date
      self.visible_start = code_review.visible_date
    else
      self.always_visible = true
    end
  end

  def set_visible_end
    self.visible_end = visible_start.present? ? calculate_end_date : nil
    save
  end

  def calculate_end_date
    # Evening: 9am the next Sunday
    # FT & PT: 8am the next Monday
    is_evening = code_review.course.parttime? && code_review.course.evening?
    visible_start.beginning_of_week(:sunday) + (is_evening ? 7.days + 9.hours : 8.days + 8.hours)
  end

  def current_time
    zone = ActiveSupport::TimeZone[code_review.course.office.time_zone]
    Time.now.in_time_zone(zone)
  end
end
