class TranscriptsController < ApplicationController
  authorize_resource

  def show
    @transcript = Transcript.new(current_student)
  end
end
