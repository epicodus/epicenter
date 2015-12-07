feature 'viewing a ticket' do
	it 'shows the ticket on the ticket show page' do
		ticket = FactoryGirl.create(:ticket)
		visit ticket_path(ticket)
		expect(page).to have_content ticket.student_names
	end

	it 'shows a list of all open tickets in the queue' do
		ticket = FactoryGirl.create(:ticket)
		visit queue_path
		expect(page).to have_content ticket.student_names
	end

	it 'shows no tickets in the queue when they are all closed' do
		visit queue_path
		expect(page).to have_content 'There are not currently any tickets. Well done!'
	end
end

feature 'creating a ticket' do
	let!(:course) { FactoryGirl.create(:course) }

	it 'allows any user to create a ticket' do
		visit help_path
		fill_in 'Your names', with: 'Zoltan and Marta'
		fill_in 'Your location in the room', with: 'By the window'
		select course.description, from: 'ticket_course_id'
		fill_in 'ticket_note', with: 'Loopy over loops'
		click_button 'Submit request'
		expect(page).to have_content "We're on it."
	end
end

feature 'closing a ticket' do
	let(:admin) { FactoryGirl.create(:admin)}
	let!(:ticket_1) { FactoryGirl.create(:ticket)}
	let!(:ticket_2) { FactoryGirl.create(:ticket)}

	it 'allows an admin to close a ticket from the queue' do
		login_as(admin, scope: :admin)
		visit queue_path
		find("#ticket-#{ticket_1.id}").click
		within "#ticket-#{ticket_1.id}" do
			click_link 'Close ticket'
		end
		expect(page).to have_content "Ticket ##{ticket_1.id} closed."
	end

	it 'allows any user to close a ticket from the ticket show page' do
		visit ticket_path(ticket_2)
		click_link "Nevermind, we've got it"
		expect(page).to have_content "Ticket ##{ticket_2.id} closed."
	end
end
