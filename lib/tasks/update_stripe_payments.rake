desc "add location descriptor to all stripe payments"
task :update_stripe_payments => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'payments.txt')
  File.open(filename, 'w') do |file|
    payments_updated = []

    Student.all.order(:created_at).each do |student|
      if student.payments.count > 0
        if student.courses.count == 0 # *** NO COURSES LISTED ***
          student.payments.each do |payment|
            if payment.stripe_transaction
              description = "#{student.id}; #{student.name}; #{payment.amount / 100}; ?; ?; ?; NO COURSES LISTED; #{payment.stripe_transaction}"
              file.puts(description)
              payments_updated.push(payment)
            end
          end
        else # *** EVERYTHING NORMAL ***
          first_course = student.courses.order(:start_date).first
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
                description = "#{location}; #{start_date}; Part-time;"
                # description = "#{student.id}; #{student.name}; #{payment.amount / 100}; #{location}; #{start_date}; Part-time; ; #{payment.stripe_transaction}"
              elsif attendance_status == "PT & FT"
                description = "#{location}; #{second_course_start_date}; Full-time"
                # description = "#{student.id}; #{student.name}; #{payment.amount / 100}; #{location}; #{second_course_start_date}; Full-time; ; #{payment.stripe_transaction}"
              else
                description = "#{location}; #{start_date}; #{attendance_status}"
                # description = "#{student.id}; #{student.name}; #{payment.amount / 100}; #{location}; #{start_date}; #{attendance_status}; ; #{payment.stripe_transaction}"
              end
              begin
                # stripe_charge = Stripe::BalanceTransaction.retrieve(payment.stripe_transaction).source
                # stripe_charge = Stripe::Charge.retrieve(stripe_charge_id)
                # stripe_charge.description = "#{location}; #{start_date}; #{attendance_status}"
                # stripe_charge.save
                file.puts(description)
                payments_updated.push(payment)
              rescue Stripe::StripeError => exception
                file.puts("STRIPE ERROR: student #{student.id}; payment #{payment.id}; #{exception.message}")
                # errors.add(:base, exception.message)
                # false
              end
            end
          end
        end
      end
    end

    # ORPHAN PAYMENTS NOT CONNECTED TO STUDENTS (just results in student_id 238 - Mieka Em)
    Payment.all.each do |payment|
      if !payments_updated.include?(payment) && payment.stripe_transaction
        description = "?; ORPHAN PAYMENT; #{payment.amount / 100}; ?; ?; ?; payment #{payment.id} | student #{payment.student_id}; #{payment.stripe_transaction}"
        file.puts(description)
      end
    end

  end
  puts "Exported to #{filename.to_s}"
end
