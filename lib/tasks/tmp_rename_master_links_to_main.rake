desc "rename links to master branches to main"
task :tmp_rename_master_links_to_main => [:environment] do
  Course.where.not(layout_file_path: nil).each do |course|
    course.update_columns(layout_file_path: course.layout_file_path.sub('/master/', '/main/'))
  end
  CodeReview.where.not(github_path: nil).each do |cr|
    cr.update_columns(github_path: cr.github_path.sub('/master/', '/main/'))
  end
end
