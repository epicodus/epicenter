class RemoveOnlineFromLanguages < ActiveRecord::Migration[5.2]
  def up
    remove_column :languages, :online
  end

  def down
    add_column :languages, :online, :boolean
  end
end
