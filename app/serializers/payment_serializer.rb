class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :description, :amount, :fee, :status, :offline, :stripe_transaction, :category, :notes, :refund_amount, :refund_notes

  def as_json
    hash = super
    payment = object
    student = Student.with_deleted.find_by_id(payment.student_id)
    hash[:created_at] = payment.created_at.to_date.to_s
    hash[:updated_at] = payment.updated_at.to_date.to_s unless payment.updated_at == payment.created_at
    hash[:email] = student.email
    hash[:office] = office_for_accounting
    # hash[:office] = student.location # WHEN ADVISORS READY: REPLACE ABOVE WITH THIS & UNCOMMENT TESTS
    hash[:start_date] = payment.refund_date.try(:to_s) || payment.description[0..9]
    hash[:end_date] = payment.cohort.end_date.to_s
    hash[:cohort] = payment.cohort.description
    hash
  end
end

private
def office_for_accounting
  object.cohort.office.short_name == 'WEB' && object.student.location == 'SEA' ? 'SEA' : object.cohort.office.short_name
end
