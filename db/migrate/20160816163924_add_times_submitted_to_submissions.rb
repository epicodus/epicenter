class AddTimesSubmittedToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :times_submitted, :integer
  end
end
