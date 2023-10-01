desc "Update CR links to point to new curriculum org"
task :tmp_update_cr_links => [:environment] do
  fromArray = ["https://github.com/epicodus-classroom/c-sharp-curriculum/blob/main/1_test_driven_development_with_c/5a_cr_teacher_c_sharp_independent_project.md", "https://github.com/epicodus-classroom/c-sharp-curriculum/blob/main/2_basic_web_apps/5a_teacher_notes_basic_mvc_web_apps.md", "https://github.com/epicodus-classroom/c-sharp-curriculum/blob/main/3_database_basics/5b_teachers_notes_database_basics_independent_project.md", "https://github.com/epicodus-classroom/c-sharp-curriculum/blob/main/4_many_to_many_relationships/5a_teachers_notes_advanced_databases_independent_project.md", "https://github.com/epicodus-classroom/c-sharp-curriculum/blob/main/5_authentication_with_identity/5a_teachers_notes_authentication_with_identity_independent_project.md", "https://github.com/epicodus-classroom/c-sharp-curriculum/blob/main/6_apis/5a_cr_building_an_api_independent_project.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/1_social_identities_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/10_changing_master_to_main_gh_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/12_jokes_and_humor_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/15_addressing_implicit_bias_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/17_understanding_stereotype_threat_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/2_identifying_and_preventing_microaggressions_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/3_equity_vs_equality_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/4_imposter_syndrome_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/5_asking_and_listening_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/6_speaking_up_reflection.md", "https://github.com/epicodus-classroom/dei-curriculum/blob/main/dei-reflections/8_recognizing_privilege_reflection.md", "https://github.com/epicodus-classroom/internship/blob/main/cover_letter_review.md", "https://github.com/epicodus-classroom/internship/blob/main/indeed_resume.md", "https://github.com/epicodus-classroom/internship/blob/main/internship_completion.md", "https://github.com/epicodus-classroom/internship/blob/main/job_search_bootcamp.md", "https://github.com/epicodus-classroom/internship/blob/main/linkedin_review.md", "https://github.com/epicodus-classroom/internship/blob/main/mock_interview.md", "https://github.com/epicodus-classroom/internship/blob/main/resume_review.md", "https://github.com/epicodus-classroom/internship/blob/main/sign_internship_agreement.md", "https://github.com/epicodus-classroom/internship/blob/main/week_16_job_application.md", "https://github.com/epicodus-classroom/internship/blob/main/week_17_job_application.md", "https://github.com/epicodus-classroom/internship/blob/main/week_18_job_application.md", "https://github.com/epicodus-classroom/internship/blob/main/week_19_job_applications.md", "https://github.com/epicodus-classroom/intro-curriculum/blob/main/1_git_html_and_css/5a_cr_git_html_and_css_independent_project.md", "https://github.com/epicodus-classroom/intro-curriculum/blob/main/2_javascript_and_web_browsers/5a_cr_javascript_and_web_browsers_independent_project.md", "https://github.com/epicodus-classroom/intro-curriculum/blob/main/3_new_arrays_and_looping/5a_cr_arrays_and_looping_independent_project.md", "https://github.com/epicodus-classroom/js-curriculum/blob/main/1_new_object_oriented_javascript/5a_cr_object_oriented_javascript_independent_project.md", "https://github.com/epicodus-classroom/js-curriculum/blob/main/2_new_test_driven_development/5a_teacher_tdd_with_javascript_independent_project.md", "https://github.com/epicodus-classroom/js-curriculum/blob/main/3_new_asynchrony_and_apis/5a_teacher_asynchrony_and_apis_independent_project.md", "https://github.com/epicodus-classroom/react-curriculum/blob/main/0_functional_programming/5a_cr_functional_programming_independent_project.md", "https://github.com/epicodus-classroom/react-curriculum/blob/main/1_react_fundamentals/5a_cr_react_fundamentals_ONE_week_independent_project.md", "https://github.com/epicodus-classroom/react-curriculum/blob/main/2_redux/5a_epicenter_cr_redux_independent_project_capstone_work_.md", "https://github.com/epicodus-classroom/react-curriculum/blob/main/3_new_react_with_nosql/5a_teacher_notes_react_with_nosql_independent_project.md", "https://github.com/epicodus-classroom/react-curriculum/blob/main/5_independent_capstone_projects/5a_capstone_independent_project_submission.md", "https://github.com/epicodus-classroom/shared-curriculum/blob/main/team_week/team_week_cr.md"]
  toArray = ["https://github.com/epicodus-curriculum/code-reviews/blob/main/c-sharp/1_cr_teacher_c_sharp_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/c-sharp/2_teacher_notes_basic_mvc_web_apps.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/c-sharp/3_teachers_notes_database_basics_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/c-sharp/4_teachers_notes_advanced_databases_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/c-sharp/5_teachers_notes_authentication_with_identity_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/c-sharp/6_cr_building_an_api_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/1_social_identities_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/10_changing_master_to_main_gh_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/12_jokes_and_humor_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/15_addressing_implicit_bias_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/17_understanding_stereotype_threat_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/2_identifying_and_preventing_microaggressions_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/3_equity_vs_equality_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/4_imposter_syndrome_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/5_asking_and_listening_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/6_speaking_up_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/dei/8_recognizing_privilege_reflection.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/cover_letter_review.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/indeed_resume.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/internship_completion.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/job_search_bootcamp.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/linkedin_review.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/mock_interview.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/resume_review.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/sign_internship_agreement.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/week_16_job_application.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/week_17_job_application.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/week_18_job_application.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/career-services/week_19_job_applications.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/intro/1_cr_git_html_and_css_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/intro/2_cr_javascript_and_web_browsers_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/intro/3_cr_arrays_and_looping_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/js/1_cr_object_oriented_javascript_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/js/2_teacher_tdd_with_javascript_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/js/3_teacher_asynchrony_and_apis_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/react/1_cr_functional_programming_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/react/2_cr_react_fundamentals_ONE_week_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/react/3_epicenter_cr_redux_independent_project_capstone_work_.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/react/4_teacher_notes_react_with_nosql_independent_project.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/react/5_capstone_independent_project_submission.md", "https://github.com/epicodus-curriculum/code-reviews/blob/main/shared/team_week_cr.md"]
  mapping = {}
  fromArray.each_with_index do |from, index|
    mapping[from] = toArray[index]
  end

  mapping.each do |from, to|
    puts "From: #{from.gsub('https://github.com/', '')}"
    puts "To: #{to.gsub('https://github.com/', '')}"
    puts ''
    CodeReview.where(github_path: from).update_all(github_path: to)
  end
end