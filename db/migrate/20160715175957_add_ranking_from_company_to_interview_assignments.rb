class AddRankingFromCompanyToInterviewAssignments < ActiveRecord::Migration
  def change
    add_column :interview_assignments, :ranking_from_company, :integer
  end
end
