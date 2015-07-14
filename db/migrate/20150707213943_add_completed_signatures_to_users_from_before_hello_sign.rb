class AddCompletedSignaturesToUsersFromBeforeHelloSign < ActiveRecord::Migration
  def change
    Student.all.each do |user|
      code_of_conduct = Signature.create(
        student_id: user.id,
        signature_request_id: 'before_hello_sign',
        is_complete: true
      )
      code_of_conduct.update(type: CodeOfConduct)

      refund_policy = Signature.create(
        student_id: user.id,
        signature_request_id: 'before_hello_sign',
        is_complete: true
      )
      refund_policy.update(type: RefundPolicy)

      enrollment_agreement = Signature.create(
        student_id: user.id,
        signature_request_id: 'before_hello_sign',
        is_complete: true
      )
      enrollment_agreement.update(type: EnrollmentAgreement)

      promissory_note = Signature.create(
        student_id: user.id,
        signature_request_id: 'before_hello_sign',
        is_complete: true
      )
      promissory_note.update(type: PromissoryNote)
    end
  end
end
