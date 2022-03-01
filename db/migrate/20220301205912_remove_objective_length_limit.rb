class RemoveObjectiveLengthLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :objectives, :content, :string
  end
end
