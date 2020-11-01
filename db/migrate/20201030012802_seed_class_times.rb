class SeedClassTimes < ActiveRecord::Migration[5.2]
  def change
    Course.skip_callback(:save, :before, :build_code_reviews)
    Course.includes(:class_times).where(class_times: {id: nil}).each do |course|
      class_times = []
      weekdays = course.class_days.map {|day| day.wday}.uniq.sort
      start_time = Time.strptime(course.start_time, "%I:%M %P").strftime('%-H:%M')
      end_time = Time.strptime(course.end_time, "%I:%M %P").strftime('%-H:%M')
      weekdays.each do |wday|
        today_start_time = wday == 0 ? '9:00' : start_time
        today_end_time = wday == 0 ? '17:00' : end_time
        class_times << ClassTime.find_or_create_by(wday: wday, start_time: today_start_time, end_time: today_end_time)
      end
      course.class_times = class_times
    end
    Course.set_callback(:save, :before, :build_code_reviews)
  end
end
