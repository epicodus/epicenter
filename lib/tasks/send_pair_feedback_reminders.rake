# maybe not actually using this; just send email immediately on sign out (in-person) / on skip (remote)
# desc "email students who have not yet filled out pair feedback for the day"
# task :send_pair_feedback_reminders => [:environment] do
#   today = Time.zone.now.to_date
#   Course.current_courses.non_internship_courses.where.not(track_id: nil).each do |course|
#     if course.is_class_day?
#       course.students.each do |student|
#         if student.signed_in_today? && student.pairs_without_feedback_today.any?
#           EmailJob.perform_later(
#             { :from => course.admin.email,
#               :to => student.email,
#               :subject => 'Pair feedback form for ' + today.strftime("%A %B ") + today.day.ordinalize,
#               :text => "If you wish to submit pair feedback for " + today.strftime("%A %B ") + today.day.ordinalize + ", please visit https://epicenter.epicodus.com/pair_feedback before midnight."
#             }
#           )
#         end
#       end
#     end
#   end
# end
