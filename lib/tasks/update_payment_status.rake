desc "update status for all payments"
task :update_payment_status => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'payments.txt')
  File.open(filename, 'w') do |file|
    Payment.all.each do |payment|
      if payment.stripe_transaction
        begin
          stripe_charge_id = Stripe::BalanceTransaction.retrieve(payment.stripe_transaction).source
          stripe_charge = Stripe::Charge.retrieve(stripe_charge_id)
          payment.update_columns(status: stripe_charge.status)
        rescue
          file.puts "FAILED: #{payment.stripe_transaction}"
        end
      end
    end
  end

  begin
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("mike@epicodus.com", {"first"=>"Mike", "last" => "Goren"});
    mb_obj.add_recipient(:to, "mike@epicodus.com", {"first" => "Mike", "last" => "Goren"});
    mb_obj.set_subject("payments.txt");
    mb_obj.set_text_body("rake task: get_payment_descriptions_from_stripe");
    mb_obj.add_attachment(filename, "payments.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  rescue
    puts "Unable to send file. Saved as #{filename.to_s}"
  end

end
