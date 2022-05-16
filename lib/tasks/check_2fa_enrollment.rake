desc "email staff not enrolled in 2fa (weekdays)"
task :check_2fa_enrollment => [:environment] do
  unless Date.today.saturday? || Date.today.sunday?

    unenrolled_admins = []
    Admin.where(otp_required_for_login: false).or(Admin.where(otp_required_for_login: nil).where.not(sign_in_count: 0)).each do |admin|
      unenrolled_admins << admin
    end
    recipients = unenrolled_admins.pluck(:email).join(', ')
    
    if Rails.env.production? && unenrolled_admins.any?
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      message_params =  { from: 'it@epicodus.com',
                          to: recipients,
                          subject: 'Two-factor authentication is not enabled on your account',
                          text: 'Please enroll in two-factor authentication. Respond to this email if you have any questions about how to do so.'
                        }
      result = mg_client.send_message('epicodus.com', message_params)
      puts result.body.to_s
      puts "Sent #{filename.to_s}"
    elsif unenrolled_admins.any?
      puts 'Not enrolled in 2fa: ' + recipients
    else
      puts "All admins who have logged in at least once are enrolled in 2fa!"
    end

  end
end