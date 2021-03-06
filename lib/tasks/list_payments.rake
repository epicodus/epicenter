desc "List payments created or updated since given date"
task :list_payments, [:day] => [:environment] do |t, args|
  puts ''
  puts '**************************************************'
  puts 'usage: heroku run "rake list_payments[yyyy-mm-dd]"'
  puts '(Date defaults to yesterday if no date entered.)'
  puts '**************************************************'
  puts ''
  day = args.day || (Date.today - 1.day).to_s
  stripe = true
  offline = true

  ids = []
  ids += Payment.where(offline: [nil, false]).pluck(:id) if stripe
  ids += Payment.where(offline: true).pluck(:id) if offline
  payments = Payment.where(id: ids)

  filename = File.join(Rails.root.join('tmp'), 'list_payments.txt')
  File.open(filename, 'w') do |file|
    file.puts "id, description, email, status, created, updated, amount, refund, stripe_txn"
    payments.where('updated_at >= ?', Date.parse(day)).order(:created_at).each do |payment|
      student = Student.with_deleted.find(payment.student_id)
      refund_amount = payment.refund_amount / 100 if payment.refund_amount
      stripe_txn = payment.stripe_transaction || 'offline'
      file.puts "#{payment.id}, #{payment.description}, #{student.try(:email)}, #{payment.status}, #{payment.created_at.to_date}, #{payment.updated_at.to_date unless payment.created_at == payment.updated_at}, #{payment.amount / 100}, #{refund_amount}, #{stripe_txn}"
    end
  end

  if Rails.env.production?
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("it@epicodus.com");
    mb_obj.add_recipient(:to, "mike@epicodus.com");
    mb_obj.set_subject("rake task: list_payments");
    mb_obj.set_text_body("rake task: list_payments");
    mb_obj.add_attachment(filename, "list_payments.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  else
    puts "Exported #{filename.to_s}"
  end
end
