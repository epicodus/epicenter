class AddColumnTimestampsToSubmissionsTable < ActiveRecord::Migration
  def change
    add_timestamps :submissions
  end
end
