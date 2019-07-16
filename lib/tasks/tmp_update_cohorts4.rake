desc "Rename cohorts in Close"
task :tmp_update_cohorts4 => [:environment] do
  filename = File.join(Rails.root.join('tmp'), 'tmp_update_cohorts4.txt')
  File.open(filename, 'w') do |file|
    # cohorts_conversion = {}
    # Cohort.all.each do |cohort|
    #   if cohort.track.nil?
    #     description = "#{cohort.start_date.to_s} to #{cohort.end_date.to_s} #{cohort.office.short_name} ALL"
    #   else
    #     description = "#{cohort.start_date.to_s} to #{cohort.end_date.to_s} #{cohort.office.short_name} #{cohort.track.description}"
    #   end
    #   cohorts_conversion[cohort.description] = description
    # end
    # file.puts cohorts_conversion
    # file.puts ""

    # cohorts_conversion = {"PT: 2015-08 PDX Part-time (Aug 31 - Oct 28)"=>"2015-08-31 to 2015-10-28 PDX Part-Time Intro to Programming", "2016-01 PDX Java/Android (Jan 4 - Jul 8)"=>"2016-01-04 to 2016-07-08 PDX Java/Android", "2016-01 PDX C#/.NET (Jan 4 - Jul 8)"=>"2016-01-04 to 2016-07-08 PDX C#/.NET", "2016-01 PDX CSS/Design (Jan 4 - Jul 8)"=>"2016-01-04 to 2016-07-08 PDX CSS/Design", "2016-01 PDX PHP/Drupal (Jan 4 - Jul 8)"=>"2016-01-04 to 2016-07-08 PDX PHP/Drupal", "2016-01 PDX ALL (Jan 4 - Jul 8)"=>"2016-01-04 to 2016-07-08 PDX ALL", "PT: 2016-01 PDX Part-time (Jan 4 - Apr 13)"=>"2016-01-04 to 2016-04-13 PDX Part-Time Intro to Programming", "2016-01 PDX ALL (Jan 4 - Jun 3)"=>"2016-01-04 to 2016-06-03 PDX ALL", "2016-01 PDX Ruby/Rails (Jan 4 - Jun 3)"=>"2016-01-04 to 2016-06-03 PDX Ruby/Rails", "2016-01 PDX Java/Android (Jan 4 - Jun 3)"=>"2016-01-04 to 2016-06-03 PDX Java/Android", "2016-03 PDX Java/Android (Mar 14 - Sep 16)"=>"2016-03-14 to 2016-09-16 PDX Java/Android", "2016-03 PDX ALL (Mar 14 - Sep 16)"=>"2016-03-14 to 2016-09-16 PDX ALL", "2016-03 PDX CSS/Design (Mar 14 - Sep 16)"=>"2016-03-14 to 2016-09-16 PDX CSS/Design", "PT: 2016-04 PDX Part-time (Apr 18 - Jul 27)"=>"2016-04-18 to 2016-07-27 PDX Part-Time Intro to Programming", "2016-05 PDX CSS/Design (May 23 - Nov 18)"=>"2016-05-23 to 2016-11-18 PDX CSS/Design", "2016-05 PDX Ruby/Rails (May 23 - Nov 18)"=>"2016-05-23 to 2016-11-18 PDX Ruby/Rails", "2016-05 PDX C#/.NET (May 23 - Nov 18)"=>"2016-05-23 to 2016-11-18 PDX C#/.NET", "2016-05 PDX ALL (May 23 - Nov 18)"=>"2016-05-23 to 2016-11-18 PDX ALL", "2016-06 SEA C#/.NET (Jun 6 - Dec 9)"=>"2016-06-06 to 2016-12-09 SEA C#/.NET", "2016-08 PDX Java/Android (Aug 1 - Feb 24)"=>"2016-08-01 to 2017-02-24 PDX Java/Android", "2016-08 SEA C#/.NET (Aug 1 - Feb 17)"=>"2016-08-01 to 2017-02-17 SEA C#/.NET", "PT: 2016-08 PDX Part-time (Aug 1 - Nov 9)"=>"2016-08-01 to 2016-11-09 PDX Part-Time Intro to Programming", "2016-08 PDX ALL (Aug 1 - Feb 24)"=>"2016-08-01 to 2017-02-24 PDX ALL", "2016-08 PHL PHP/Drupal (Aug 1 - Feb 17)"=>"2016-08-01 to 2017-02-17 PHL PHP/Drupal", "2016-08 PDX CSS/Design (Aug 1 - Feb 24)"=>"2016-08-01 to 2017-02-24 PDX CSS/Design", "2016-08 PDX PHP/Drupal (Aug 1 - Feb 24)"=>"2016-08-01 to 2017-02-24 PDX PHP/Drupal", "2016-10 PDX ALL (Oct 10 - Apr 28)"=>"2016-10-10 to 2017-04-28 PDX ALL", "2016-10 PDX CSS/Design (Oct 10 - Apr 28)"=>"2016-10-10 to 2017-04-28 PDX CSS/Design", "2016-10 PDX Ruby/Rails (Oct 10 - Apr 28)"=>"2016-10-10 to 2017-04-28 PDX Ruby/Rails", "2016-10 PDX C#/.NET (Oct 10 - Apr 28)"=>"2016-10-10 to 2017-04-28 PDX C#/.NET", "2017-01 PDX PHP/Drupal (Jan 2 - Jul 7)"=>"2017-01-02 to 2017-07-07 PDX PHP/Drupal", "PT: 2017-01 PDX Part-time (Jan 2 - Apr 12)"=>"2017-01-02 to 2017-04-12 PDX Part-Time Intro to Programming", "PT: 2017-01 SEA Part-time (Jan 2 - Apr 12)"=>"2017-01-02 to 2017-04-12 SEA Part-Time Intro to Programming", "2017-01 SEA C#/.NET (Jan 2 - Jul 7)"=>"2017-01-02 to 2017-07-07 SEA C#/.NET", "2017-02 PDX Java/Android (Feb 6 - Aug 11)"=>"2017-02-06 to 2017-08-11 PDX Java/Android", "2017-02 SEA PHP/Drupal (Feb 6 - Aug 11)"=>"2017-02-06 to 2017-08-11 SEA PHP/Drupal", "2017-03 PDX Ruby/Rails (Mar 13 - Sep 15)"=>"2017-03-13 to 2017-09-15 PDX Ruby/Rails", "2017-03 SEA Ruby/Rails (Mar 13 - Sep 15)"=>"2017-03-13 to 2017-09-15 SEA Ruby/Rails", "2017-04 PDX C#/.NET (Apr 17 - Oct 20)"=>"2017-04-17 to 2017-10-20 PDX C#/.NET", "PT: 2017-04 PDX Part-time (Apr 17 - Jul 26)"=>"2017-04-17 to 2017-07-26 PDX Part-Time Intro to Programming", "2017-04 PDX CSS/Design (Apr 17 - Oct 20)"=>"2017-04-17 to 2017-10-20 PDX CSS/Design", "PT: 2017-04 SEA Part-time (Apr 17 - Jul 26)"=>"2017-04-17 to 2017-07-26 SEA Part-Time Intro to Programming", "2017-05 PDX PHP/React (May 22 - Nov 24)"=>"2017-05-22 to 2017-11-24 PDX PHP/React", "2017-05 SEA Java/Android (May 22 - Nov 24)"=>"2017-05-22 to 2017-11-24 SEA Java/Android", "2017-06 PDX Java/Android (Jun 26 - Dec 29)"=>"2017-06-26 to 2017-12-29 PDX Java/Android", "2017-06 SEA C#/.NET (Jun 26 - Dec 29)"=>"2017-06-26 to 2017-12-29 SEA C#/.NET", "2017-07 PDX Ruby/Rails (Jul 31 - Feb 16)"=>"2017-07-31 to 2018-02-16 PDX Ruby/Rails", "2017-07 SEA Ruby/Rails (Jul 31 - Feb 16)"=>"2017-07-31 to 2018-02-16 SEA Ruby/Rails", "2017-09 PDX CSS/Design (Sep 5 - Mar 23)"=>"2017-09-05 to 2018-03-23 PDX CSS/Design", "2017-09 SEA C#/.NET (Sep 5 - Mar 23)"=>"2017-09-05 to 2018-03-23 SEA C#/.NET", "2017-09 PDX C#/.NET (Sep 5 - Mar 23)"=>"2017-09-05 to 2018-03-23 PDX C#/.NET", "PT: 2017-09 PDX Part-time (Sep 6 - Dec 13)"=>"2017-09-06 to 2017-12-13 PDX Part-Time Intro to Programming", "2017-10 SEA Ruby/Rails (Oct 9 - Apr 27)"=>"2017-10-09 to 2018-04-27 SEA Ruby/Rails", "2017-10 PDX CSS/React (Oct 9 - Apr 27)"=>"2017-10-09 to 2018-04-27 PDX Front End Development", "PT: 2017-10 SEA Part-time (Oct 9 - Jan 31)"=>"2017-10-09 to 2018-01-31 SEA Part-Time Intro to Programming", "2017-11 PDX Java/Android (Nov 13 - Jun 1)"=>"2017-11-13 to 2018-06-01 PDX Java/Android", "2018-01 PDX C#/.NET (Jan 2 - Jul 6)"=>"2018-01-02 to 2018-07-06 PDX C#/.NET", "2018-01 SEA C#/React (Jan 2 - Jul 6)"=>"2018-01-02 to 2018-07-06 SEA C#/React", "PT: 2018-01 WEB Online (Jan 2 - Apr 12)"=>"2018-01-02 to 2018-04-12 WEB Online", "2018-01 PDX Ruby/Rails (Jan 2 - Jul 6)"=>"2018-01-02 to 2018-07-06 PDX Ruby/Rails", "PT: 2018-01 PDX Part-time (Jan 3 - Apr 11)"=>"2018-01-03 to 2018-04-11 PDX Part-Time Intro to Programming", "2018-03 SEA C#/React (Mar 12 - Sep 14)"=>"2018-03-12 to 2018-09-14 SEA C#/React", "2018-03 PDX Java/React (Mar 12 - Sep 14)"=>"2018-03-12 to 2018-09-14 PDX Java/React", "2018-03 PDX Front End Development (Mar 12 - Sep 14)"=>"2018-03-12 to 2018-09-14 PDX Front End Development", "PT: 2018-04 PDX Part-time (Apr 16 - Jul 25)"=>"2018-04-16 to 2018-07-25 PDX Part-Time Intro to Programming", "2018-05 SEA C#/React (May 21 - Nov 23)"=>"2018-05-21 to 2018-11-23 SEA C#/React", "2018-05 PDX Ruby/Rails (May 21 - Nov 23)"=>"2018-05-21 to 2018-11-23 PDX Ruby/Rails", "2018-05 PDX C#/React (May 21 - Nov 23)"=>"2018-05-21 to 2018-11-23 PDX C#/React", "2018-07 SEA C#/React (Jul 30 - Feb 22)"=>"2018-07-30 to 2019-02-22 SEA C#/React", "PT: 2018-07 PDX Part-time (Jul 30 - Nov 7)"=>"2018-07-30 to 2018-11-07 PDX Part-Time Intro to Programming", "2018-07 PDX Front End Development (Jul 30 - Feb 22)"=>"2018-07-30 to 2019-02-22 PDX Front End Development", "Fidgetech"=>"Fidgetech", "2018-10 SEA C#/React (Oct 8 - May 3)"=>"2018-10-08 to 2019-05-03 SEA C#/React", "2018-10 PDX C#/React (Oct 8 - May 3)"=>"2018-10-08 to 2019-05-03 PDX C#/React", "2018-10 PDX Ruby/React (Oct 8 - May 3)"=>"2018-10-08 to 2019-05-03 PDX Ruby/React", "PT: 2019-01 SEA Part-time (Jan 2 - Apr 10)"=>"2019-01-02 to 2019-04-10 SEA Part-Time Intro to Programming", "PT: 2019-01 PDX Part-time (Jan 2 - Apr 10)"=>"2019-01-02 to 2019-04-10 PDX Part-Time Intro to Programming", "2019-01 PDX Front End Development (Jan 7 - Jul 12)"=>"2019-01-07 to 2019-07-12 PDX Front End Development", "2019-01 SEA C#/React (Jan 7 - Jul 12)"=>"2019-01-07 to 2019-07-12 SEA C#/React", "2019-03 PDX C#/React (Mar 18 - Sep 20)"=>"2019-03-18 to 2019-09-20 PDX C#/React", "2019-03 SEA C#/React (Mar 18 - Sep 20)"=>"2019-03-18 to 2019-09-20 SEA C#/React", "PT: 2019-04 PDX Part-time (Apr 22 - Jul 31)"=>"2019-04-22 to 2019-07-31 PDX Part-Time Intro to Programming", "PT: 2019-04 SEA Part-time (Apr 22 - Jul 31)"=>"2019-04-22 to 2019-07-31 SEA Part-Time Intro to Programming"}

    # cohorts_conversion = {"2000-01 PDX Ruby/Rails (Jan 3 - Jul 7)"=>"2000-01-03 to 2000-07-07 PDX Ruby/Rails", "2017-01 PDX PHP/Drupal (Jan 2 - Jul 7)"=>"2017-01-02 to 2017-07-07 PDX PHP/Drupal", "2017-01 SEA C#/.NET (Jan 2 - Jul 7)"=>"2017-01-02 to 2017-07-07 SEA C#/.NET", "2017-03 PDX Ruby/Rails (Mar 13 - Sep 15)"=>"2017-03-13 to 2017-09-15 PDX Ruby/Rails", "2017-05 PDX PHP/React (May 22 - Dec 1)"=>"2017-05-22 to 2017-12-01 PDX PHP/React", "2017-05 SEA Java/Android (May 22 - Dec 1)"=>"2017-05-22 to 2017-12-01 SEA Java/Android", "2017-06 PDX Java/Android (Jun 26 - Jan 12)"=>"2017-06-26 to 2018-01-12 PDX Java/Android", "2017-06 SEA C#/.NET (Jun 26 - Jan 12)"=>"2017-06-26 to 2018-01-12 SEA C#/.NET", "2017-09 SEA CSS/Design (Sep 5 - Mar 23)"=>"2017-09-05 to 2018-03-23 SEA CSS/Design", "2017-10 PDX CSS/React (Oct 9 - Apr 27)"=>"2017-10-09 to 2018-04-27 PDX CSS/React", "2017-10 PDX PHP/React (Oct 9 - Apr 27)"=>"2017-10-09 to 2018-04-27 PDX PHP/React", "2017-10 SEA Java/Android (Oct 9 - Apr 27)"=>"2017-10-09 to 2018-04-27 SEA Java/Android", "2017-11 SEA C#/React (Nov 13 - Jun 1)"=>"2017-11-13 to 2018-06-01 SEA C#/React", "2018-01 SEA Ruby/Rails (Jan 2 - Jul 6)"=>"2018-01-02 to 2018-07-06 SEA Ruby/Rails", "2018-03 PDX CSS/React (Mar 12 - Sep 14)"=>"2018-03-12 to 2018-09-14 PDX CSS/React", "2018-10 PDX C#/React (Oct 8 - Apr 26)"=>"2018-10-08 to 2019-04-26 PDX C#/React", "2018-10 PDX Ruby/Rails (Oct 8 - Apr 26)"=>"2018-10-08 to 2019-04-26 PDX Ruby/Rails", "2018-10 PDX Ruby/React (Oct 8 - Apr 26)"=>"2018-10-08 to 2019-04-26 PDX Ruby/React", "2018-10 SEA C#/React (Oct 8 - Apr 26)"=>"2018-10-08 to 2019-04-26 SEA C#/React", "2019-01 PDX Front End Development (Jan 7 - Jul 5)"=>"2019-01-07 to 2019-07-05 PDX Front End Development", "2019-01 SEA C#/React (Jan 7 - Jul 5)"=>"2019-01-07 to 2019-07-05 SEA C#/React", "PT: 2000-01 PDX Part-time (Jan 3 - Jul 7)"=>"2000-01-03 to 2000-07-07 PDX Part-Time Intro to Programming", "PT: 2017-04 SEA Part-time (Apr 17 - Jul 26)"=>"2017-04-17 to 2017-07-26 SEA Part-Time Intro to Programming", "PT: 2017-09 SEA Part-time (Sep 6 - Dec 13)"=>"2017-09-06 to 2017-12-13 SEA Part-Time Intro to Programming"}

    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    close_io_client.list_leads('"custom.Cohort - Part-time":*', 5000)[:data].each do |lead|
      existing_cohort_description = lead['custom']['Cohort - Part-time']
      email = lead['contacts'].first['emails'].first['email']
      student = Student.with_deleted.find_by(email: email)
      file.puts existing_cohort_description
      # if existing_cohort_description.include?(' - ')
        # new_cohort_description = cohorts_conversion[existing_cohort_description]
        # file.puts existing_cohort_description
        # file.puts new_cohort_description || 'NOT FOUND'
        # file.puts ""
        # if new_cohort_description
          # close_io_client.update_lead(lead['id'], {'custom.Cohort - Applied': new_cohort_description })
          # file.puts existing_cohort_description + " => " + new_cohort_description
        # end
      # end
      # if existing_cohort_description.include?(' - ')
      #   new_cohort_description = cohorts_conversion[existing_cohort_description]
      #   if new_cohort_description
      #     file.puts existing_cohort_description + " => " + new_cohort_description
      #     close_io_client.update_lead(lead['id'], {'custom.Cohort - Applied': new_cohort_description })
      #   end
      # end
    end
  end

  # if Rails.env.production?
  #   mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
  #   mb_obj = Mailgun::MessageBuilder.new()
  #   mb_obj.set_from_address("it@epicodus.com");
  #   mb_obj.add_recipient(:to, "mike@epicodus.com");
  #   mb_obj.set_subject("rake task: tmp_update_cohorts4");
  #   mb_obj.set_text_body("rake task: tmp_update_cohorts4");
  #   mb_obj.add_attachment(filename, "tmp_update_cohorts4.txt");
  #   result = mg_client.send_message("epicodus.com", mb_obj)
  #   puts result.body.to_s
  #   puts "Sent #{filename.to_s}"
  # else
  #   puts "Exported #{filename.to_s}"
  # end
end