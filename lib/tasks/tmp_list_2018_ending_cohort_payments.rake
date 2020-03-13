desc "list all payments for students in FT cohorts that ended in 2018"
task :tmp_list_2018_ending_cohort_payments => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_list_2018_ending_cohort_payments.txt')
  File.open(filename, 'w') do |file|
    cohorts = Cohort.fulltime_cohorts.where('end_date BETWEEN ? AND ?', Date.parse('2018-01-01'), Date.parse('2019-01-01')).order(:end_date)
    cohorts.each do |cohort|
      file.puts "#{cohort.description}"
      file.puts ""
      cohort.ending_cohort_students.each do |student|
        file.puts student.name
        student.payments.each do |payment|
          date = payment.created_at.strftime('%Y-%m-%d')
          amount = payment.amount ? payment.amount / 100 : 0
          refund_amount = payment.refund_amount ? payment.refund_amount / 100 : 0
          file.puts "#{date}, #{amount}, #{refund_amount}"
        end
        file.puts ""
      end
      file.puts ""
      file.puts "--------------"
      file.puts ""
    end
  end
  puts "Exported #{filename.to_s}"
end
