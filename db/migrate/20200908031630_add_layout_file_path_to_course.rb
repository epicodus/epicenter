class AddLayoutFilePathToCourse < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :layout_file_path, :string
  end
end
