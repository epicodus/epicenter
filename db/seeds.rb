#Payment Plans

plans = [
  ["Spring 2015 loan", 0, 625_00, 5000_00],
  ["Summer 2014 loan", 0, 600_00, 5000_00],
  ["Winter 2015 loan", 200_00, 600_00, 5000_00],
  ["Winter 2015 up-front", 3400_00, 0, 3400_00]
]

plans.each do |name, upfront_amount, total_amount|
  Plan.create(name: name, upfront_amount: upfront_amount, total_amount: total_amount)
end


#Courses / Classes

courses = [
  ["Spring 2014", [Date.parse("November 16, 2015"), Date.parse("November 17, 2015")], Time.parse("08:00:00 AM"), Time.parse("17:00:00 PM")],
  ["Summer 2015", [Date.parse("November 16, 2015"), Date.parse("November 17, 2015")], Time.parse("08:00:00 AM"), Time.parse("17:00:00 PM")],
  ["Winter 2015", [Date.parse("November 16, 2015"), Date.parse("November 17, 2015")], Time.parse("08:00:00 AM"), Time.parse("17:00:00 PM")]
]

courses.each do |description, class_days, start_time, end_time|
  Course.create!(description: description, class_days: class_days, start_time: start_time, end_time: end_time)
end
