class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.string :description

      t.timestamps
    end
  end
end
