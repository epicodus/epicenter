class RemoveColumnsFromLanguages < ActiveRecord::Migration[5.2]
  def change
    remove_column :languages, :number_of_days, :integer
    remove_column :languages, :skip_holiday_weeks, :boolean
    remove_column :languages, :parttime, :boolean
    Language.find_by(name: 'Evening').update(archived: true)
  end
end
