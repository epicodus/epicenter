class ChangeLinkInSubmissions < ActiveRecord::Migration
  def up
    change_column :submissions, :link,  :text
  end

  def down
    change_column :submissions, :link,  :string
  end
end
