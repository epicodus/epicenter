class ChangeColumnNamesInCompanies < ActiveRecord::Migration
  def change
    rename_column :companies, :company_description, :description
    rename_column :companies, :company_website, :website
    rename_column :companies, :company_address, :address
  end
end
