class AddTimestampsToCostAdjustments < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :cost_adjustments, null: true
  end
end
