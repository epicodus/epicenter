class TicketsController < ApplicationController

  def index
    @tickets = Ticket.all
  end

  def new
    @tickets = Ticket.all
  end

  def create
    ticket = Ticket.new(ticket_params)
    if ticket.save
      redirect_to ticket_path(ticket)
      flash[:notice] = "We're on it. There " +
                       "is".pluralize(ticket.other_open_tickets.count) +
                       " currently " +
                       ticket.other_open_tickets.count.to_s + " " +
                       "ticket".pluralize(ticket.other_open_tickets.count) +
                       " ahead of you."
    else
      render 'new'
    end
  end

  def show
    @ticket = Ticket.find(params[:id])
  end

  def destroy
    ticket = Ticket.find(params[:id])
    ticket.destroy
    redirect_to queue_path, notice: "Ticket ##{ticket.id} closed."
  end

  private

  def ticket_params
    params.require(:ticket).permit(:course_id, :student_names, :note, :location)
  end
end
