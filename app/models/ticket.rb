class Ticket < ActiveRecord::Base
	acts_as_paranoid

	belongs_to :course

	validates :student_names, presence: true
	validates :note, presence: true
	validates :course_id, presence: true
	validates :location, presence: true

	def other_open_tickets
		Ticket.where.not(id: id)
	end
end
