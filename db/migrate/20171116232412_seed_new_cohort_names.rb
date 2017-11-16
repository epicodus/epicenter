class SeedNewCohortNames < ActiveRecord::Migration[5.1]
  def up
    Cohort.all.each do |cohort|
      track_description = cohort.track.try(:description) || "ALL"
      description = "#{cohort.start_date.strftime('%Y-%m')} #{cohort.office.short_name} #{track_description} (#{cohort.start_date.strftime('%b %-d')} - #{cohort.end_date.strftime('%b %-d')})"
      description = "PT: " + description if track_description == 'Part-time'
      cohort.update_columns(description: description)
    end
  end

  def down
  end
end
