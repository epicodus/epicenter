class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.text   :company_description
      t.string :company_website
      t.string :company_address
      t.string :contact_name
      t.string :contact_phone
      t.string :contact_email
      t.string :contact_title
    end
  end
end
