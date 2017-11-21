class SeedOnlineCohort < ActiveRecord::Migration[5.1]
  def up
    office = Office.create(name: 'Online', short_name: 'WEB', time_zone: 'Pacific Time (US & Canada)')
    track = Track.create(description: 'Online')
    language = Language.create(name: 'Online', level: 0)
    track.languages << language
    admin = Admin.find_by(email: 'elysia@epicodus.com')
    cohort = Cohort.create(start_date: Date.parse('2018-01-02'), office: office, track: track, admin: admin)
  end

  def down
    Office.find_by(name: 'Online').destroy
    Track.find_by(name: 'Online').destroy
    Language.find_by(name: 'Online').destroy
    Cohort.find_by(description: 'PT: 2018-01 WEB Online (Jan 2 - Apr 12)').destroy
  end
end
