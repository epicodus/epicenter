class StudentInternshipAgreement < Signature

  attr_accessor :sign_url
  before_create :create_signature_request

  def self.create_from_signature_id(signature_id)
    student = Signature.find_by(signature_id: signature_id).student
    code_review = student.internship_course.code_reviews.find_by(title: "Sign internship agreement") || student.internship_course.code_reviews.find_by(title: "Sign Internship Agreement")
    submission = Submission.find_or_create_by(student: student, code_review: code_review)
    review = submission.reviews.create(note: "provisionally marked as completed", student_signature: "n/a", admin_id: 198)
    Grade.create(score: Score.find_by(value: 3), objective: code_review.objectives.first, review: review)
    student.crm_lead.update({ "custom.#{Rails.application.config.x.crm_fields['SIGNED_INTERNSHIP_AGREEMENT']}": 'Yes' })
  end

private

  def create_signature_request
    @subject = 'Sign to accept the Student Internship Agreement'
    @file = ENV['STUDENT_INTERNSHIP_AGREEMENT_DOCUMENT_URL']
    super
  end
end
