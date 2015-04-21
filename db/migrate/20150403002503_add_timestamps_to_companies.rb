class AddTimestampsToCompanies < ActiveRecord::Migration
  def change
    add_timestamps :companies
  end
end
