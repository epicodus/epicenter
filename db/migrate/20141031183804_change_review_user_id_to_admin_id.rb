class ChangeReviewUserIdToAdminId < ActiveRecord::Migration
  def change
    rename_column :reviews, :user_id, :admin_id
  end
end
