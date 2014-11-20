class TranscriptsController < ApplicationController
  def show
    @transcript = Transcript.new(current_student)
  end
end
