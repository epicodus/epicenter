class AddExemptToSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_column :submissions, :exempt, :boolean
  end
end
