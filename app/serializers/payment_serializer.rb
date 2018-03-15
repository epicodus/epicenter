class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :description, :amount, :fee, :status, :offline, :stripe_transaction, :category, :notes, :refund_amount, :refund_basis

  def as_json
    hash = super
    hash[:email] = Student.with_deleted.find_by_id(object.student_id).try(:email)
    hash[:refund_date] = object.refund_date.to_s if object.refund_date
    hash
  end
end
