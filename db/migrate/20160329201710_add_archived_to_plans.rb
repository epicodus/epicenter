class AddArchivedToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :archived, :boolean
  end
end
