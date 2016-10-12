desc "add location descriptor to all stripe payments"
task :add_description_to_stripe_payments => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'payments.txt')
  File.open(filename, 'w') do |file|
    Student.all.order(:created_at).each do |student|
      if student.payments.count > 0 && student.courses.count > 0
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
              description = "#{location}; #{start_date}; Part-time"
            elsif attendance_status == "PT & FT"
              description = "#{location}; #{second_course_start_date}; Full-time"
            else
              description = "#{student.id}; #{location}; #{start_date}; #{attendance_status}"
            end
            begin
              stripe_charge_id = Stripe::BalanceTransaction.retrieve(payment.stripe_transaction).source
              stripe_charge = Stripe::Charge.retrieve(stripe_charge_id)
              stripe_charge.description = description
              stripe_charge.save
              file.puts(description)
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
  puts "Exported to #{filename.to_s}"
end
