class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :description, :amount, :fee, :status, :refund_amount, :offline, :stripe_transaction, :category, :notes

  def as_json
    hash = super
    hash[:email] = Student.with_deleted.find_by_id(object.student_id).try(:email)
    hash
  end
end
