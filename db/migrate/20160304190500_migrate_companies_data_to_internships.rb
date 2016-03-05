class MigrateCompaniesDataToInternships < ActiveRecord::Migration
  def up
    Company.all.each do |company|
      company.internships.each do |internship|
        internship.update(name: company.name, website: company.website, address: company.address)
      end
    end
  end

  def down
    Internship.update_all(name: nil, website: nil, address: nil)
  end
end
