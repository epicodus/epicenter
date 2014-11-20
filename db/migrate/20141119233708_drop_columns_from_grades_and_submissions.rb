class DropColumnsFromGradesAndSubmissions < ActiveRecord::Migration
  def change
    remove_column :grades, :comment, :string
    remove_column :submissions, :note, :string
  end
end
