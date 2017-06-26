class RemoveBlurbFromSubmissions < ActiveRecord::Migration
  def change
    remove_column :submissions, :blurb, :string
  end
end
