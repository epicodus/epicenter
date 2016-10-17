desc "copy descriptions from stripe to epicenter db"
task :get_payment_descriptions_from_stripe => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'payments.txt')
  File.open(filename, 'w') do |file|
    Payment.all.each do |payment|
      if payment.stripe_transaction
        begin
          stripe_charge_id = Stripe::BalanceTransaction.retrieve(payment.stripe_transaction).source
          stripe_charge = Stripe::Charge.retrieve(stripe_charge_id)
          if stripe_charge.description && stripe_charge.description != ""
            payment.update(description, stripe_charge.description)
            file.puts("#{payment.id}; #{payment.description}")
          else
            file.puts("#{payment.id}; NO STRIPE DESCRIPTION")
          end
        rescue Stripe::RateLimitError => exception
          file.puts("#{payment.id}; STRIPE RATE LIMIT ERROR: #{exception.message}")
        rescue Stripe::StripeError => exception
          file.puts("#{payment.id}; STRIPE ERROR: #{exception.message}")
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
