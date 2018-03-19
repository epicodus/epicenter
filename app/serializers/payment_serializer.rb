class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :description, :amount, :fee, :status, :offline, :stripe_transaction, :category, :notes, :refund_amount

  def as_json
    student = Student.with_deleted.find_by_id(object.student_id)
    hash = super
    hash[:refund_date] = object.refund_date.to_s if object.refund_date
    hash[:email] = student.try(:email)
    hash[:end_date] = student.ending_cohort.end_date.to_s if student.try(:ending_cohort)
    hash
  end
end
