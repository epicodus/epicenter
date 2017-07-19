class SeedSubmissionReviewStatus < ActiveRecord::Migration[5.1]
  def up
    Submission.all.each do |submission|
      if submission.has_been_reviewed? && submission.latest_review
        review_status = submission.latest_review.meets_expectations? ? "pass" : "fail"
        submission.update_columns(review_status: review_status)
      else
        submission.update_columns(review_status: "pending")
      end
    end
  end

  def down
    Submission.update_all(review_status: nil)
  end
end
