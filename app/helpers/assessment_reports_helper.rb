module AssessmentReportsHelper
  def score_for(student, assessment, requirement)
    if submission = student.submissions.where(assessment_id: assessment).first
      submission.latest_review.grades.where(requirement_id: requirement.id).first.score.value
    end
  end
end
