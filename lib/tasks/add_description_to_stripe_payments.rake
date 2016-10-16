desc "add description to all old stripe payments"
task :add_description_to_stripe_payments => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'payments.txt')
  File.open(filename, 'w') do |file|
    payments_updated = []
    Student.all.order(:created_at).each do |student|
      begin
        if student.payments.any?
          if student.courses.any? || student.enrollments.with_deleted.any?
            if student.courses.any?
              first_course = student.courses.order(:start_date).first
            else
              first_course = student.enrollments.with_deleted.first.course
            end
            location = first_course.office.name
            start_date = first_course.start_date.strftime("%Y-%m-%d")
            if first_course.description.include?("Evening")
              if student.courses.count == 1 || student.payments.count == 1
                attendance_status = "Part-time"
              else
                attendance_status = "PT & FT"
                second_course_start_date = student.courses[1].start_date.strftime("%Y-%m-%d")
              end
            else
              attendance_status = "Full-time"
            end
            student.payments.each_with_index do |payment, index|
              if payment.stripe_transaction
                if attendance_status == "PT & FT" && index == 0
                  description = "#{location}; #{start_date}; Part-time"
                elsif attendance_status == "PT & FT"
                  description = "#{location}; #{second_course_start_date}; Full-time"
                else
                  description = "#{location}; #{start_date}; #{attendance_status}"
                end
                begin
                  stripe_charge_id = Stripe::BalanceTransaction.retrieve(payment.stripe_transaction).source
                  stripe_charge = Stripe::Charge.retrieve(stripe_charge_id)
                  stripe_charge.description = description
                  stripe_charge.save
                  file.puts(description)
                  payments_updated.push(payment)
                rescue Stripe::StripeError => exception
                  file.puts("STRIPE ERROR: student #{student.id}; payment #{payment.id}; #{exception.message}")
                end
              end
            end
          end
        end
      rescue Exception
        file.puts("UNEXPECTED ERROR: #{student.id}; #{student.name}")
      end
    end
   
    # STUDENTS WITHOUT ENROLLMENTS & ORPHAN STUDENTS (note: student id 238 = Mieka Em)
    file.puts("")
    file.puts("NOT UPDATED:")
    Payment.all.each do |payment|
      if !payments_updated.include?(payment) && payment.stripe_transaction
        if payment.student
          description = "#{payment.student.id}; #{payment.student.name}; #{payment.amount / 100}; payment #{payment.id} | student #{payment.student_id}"
        else
          description = "?; ORPHAN PAYMENT; #{payment.amount / 100}; payment #{payment.id} | student #{payment.student_id}"
        end
        file.puts(description)
      end
    end
  
  end

  begin
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
    mb_obj = Mailgun::MessageBuilder.new()
    mb_obj.set_from_address("mike@epicodus.com", {"first"=>"Mike", "last" => "Goren"});
    mb_obj.add_recipient(:to, "mike@epicodus.com", {"first" => "Mike", "last" => "Goren"});
    mb_obj.set_subject("payments.txt");
    mb_obj.set_text_body("payments.txt should be attached");
    mb_obj.add_attachment(filename, "payments.txt");
    result = mg_client.send_message("epicodus.com", mb_obj)
    puts result.body.to_s
    puts "Sent #{filename.to_s}"
  rescue
    puts "Unable to send file. Saved as #{filename.to_s}"
  end
end
