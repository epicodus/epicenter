class SeedUpdatedPtJsReactTrack < ActiveRecord::Migration[5.2]
  def change
    Language.find_by(name: 'JavaScript (part-time track)').update(number_of_days: 24)
    Language.find_by(name: 'React (part-time track)').update(number_of_days: 36)
  end
end
