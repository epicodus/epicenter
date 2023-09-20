desc "set crs to be visible again if never submitted"
# on Tuesdays, if no submission awaiting review, set visible_start to Wed/Thu and visible_end to the following Sun/Mon morning
# EVENING: make visible Wed 9pm
# FT & PT: make visible Thu 5pm
# don't do anything if always_visible
task :update_cr_visibility => [:environment] do
  if Date.today.tuesday?
    past_code_reviews = CodeReview.current_cohort_code_reviews.where('visible_date < ?', Date.today)
    CodeReviewVisibility.where(code_review: past_code_reviews).each do |crv|
      unless crv.code_review.submission_for(crv.student).present? # do we also want to include students missing a resubmission?
        make_code_review_visible(crv)
      end
    end
  end
end

def make_code_review_visible(crv)
  is_evening = crv.code_review.course.parttime? && crv.code_review.course.evening?
  visible_start = Date.today.beginning_of_week(:sunday) + (is_evening ? 3.days + 21.hours : 4.days + 17.hours)
  crv.update(visible_start: visible_start)
end
