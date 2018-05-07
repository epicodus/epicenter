desc "separate refunds from payments"
task :tmp_separate_refunds => [:environment] do
  Refund.skip_callback(:create, :before, :issue_refund)
  PaymentBase.skip_callback(:create, :before, :check_amount)
  PaymentBase.skip_callback(:create, :before, :set_offline_status)
  PaymentBase.skip_callback(:create, :before, :set_category)
  PaymentBase.skip_callback(:create, :before, :set_description)
  PaymentBase.skip_callback(:create, :after, :update_crm)
  PaymentBase.skip_callback(:create, :after, :send_webhook)

  puts "CREATING REFUNDS FOR STRIPE REFUNDS:"
  Payment.where.not(offline: true).where.not(refund_amount: nil).each do |p|
    puts p.student.try(:email) || p.student_id
    Refund.create(refund_issued: true, category: 'refund', status: 'succeeded', offline: false, original_payment_id: p.id, student_id: p.student_id, created_at: p.updated_at, updated_at: p.updated_at, refund_amount: p.refund_amount, refund_notes: p.refund_notes, refund_date: p.refund_date, description: p.description)
    p.update_columns(refund_amount: nil, refund_notes: nil, refund_date: nil, refund_issued: nil)
  end

  puts "CREATING REFUNDS FOR OFFLINE REFUNDS (NEWER):"
  Payment.where(category: 'refund').where(amount: 0).each do |p|
    puts p.student.try(:email) || p.student_id
    Refund.create(category: 'refund', status: 'offline', offline: true, original_payment_id: p.id, student_id: p.student_id, created_at: p.created_at, updated_at: p.updated_at, refund_amount: p.refund_amount, refund_notes: p.refund_notes, refund_date: p.refund_date, description: p.description)
    p.update_columns(refund_amount: nil, refund_notes: nil, refund_date: nil)
  end

  puts "CREATING REFUNDS FOR OFFLINE REFUNDS (OLDER):"
  Payment.where(category: 'refund').where('amount < 0').each do |p|
    puts p.student.try(:email) || p.student_id
    Refund.create(category: 'refund', status: 'offline', offline: true, original_payment_id: p.id, student_id: p.student_id, created_at: p.created_at, updated_at: p.updated_at, refund_amount: p.amount * -1, refund_notes: p.notes, refund_date: p.refund_date, description: p.description)
    p.update_columns(amount: 0, notes: nil)
  end
end
