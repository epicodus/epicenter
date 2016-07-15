class AddCompanyRankingToInterviewAssignments < ActiveRecord::Migration
  def change
    add_column :interview_assignments, :company_ranking, :integer
  end
end
