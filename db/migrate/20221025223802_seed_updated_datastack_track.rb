class SeedUpdatedDatastackTrack < ActiveRecord::Migration[6.1]
  def change
    old_track = Track.active.find_by(description: 'Data Engineering')
    old_track.update(archived: true)

    track = Track.create(description: 'Data Engineering')

    intro = old_track.languages.find_by(name: 'Intro')
    foundations = Language.create(name: 'Foundations', level: 1)
    data_modeling = Language.create(name: 'Data Modeling', level: 2)
    airflow_and_spark = Language.create(name: 'Airflow and Spark', level: 3)
    capstone = Language.create(name: 'Capstone', level: 4)
    internship = Language.create(name: 'Internship', level: 5)

    track.languages = [intro, foundations, data_modeling, airflow_and_spark, capstone, internship]
  end
end
