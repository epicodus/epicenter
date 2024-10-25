feature 'student note sticky' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
  let!(:sticky) { FactoryBot.create(:student_sticky_note, student: student) }

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit student_courses_path(student)
    expect(page).to_not have_content sticky.content
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
   
    before { login_as(admin, scope: :admin) }

    scenario 'can view a student sticky note', :js do
      visit student_courses_path(student)
      expect(page).to have_content student.sticky.content
    end

    scenario 'can update a student note', :js do
      visit student_courses_path(student)
      find('#sticky-note-content').click
      fill_in 'student_sticky_attributes_content', with: 'New shiny sticky note'
      click_button 'Update sticky'
      expect(page).to have_content 'New shiny sticky note'
    end

    scenario 'can create a student note if not yet created', :js do
      student.sticky.destroy
      visit student_courses_path(student)
      expect(page).to have_content 'Click to create a staff-only sticky note for this student'
      find('#sticky-note-content').click
      fill_in 'student_sticky_attributes_content', with: 'New shiny sticky note'
      click_button 'Update sticky'
      expect(page).to have_content 'New shiny sticky note'
    end
  end
end
