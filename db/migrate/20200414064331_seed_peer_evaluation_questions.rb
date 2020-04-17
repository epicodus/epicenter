class SeedPeerEvaluationQuestions < ActiveRecord::Migration[5.2]
  def up
    technical_questions =
    [
      'Ask clarifying questions?',
      'Write down inputs and outputs?',
      'Consider edge cases?',
      'Use technical language correctly?',
      'Explain their solution clearly, including summarizing the code from input to output?',
      'Correctly solve the problem?'
    ]
    professionalism_questions =
    [
      'Speak in a clear and easy to understand voice?',
      'Make eye contact?',
      'Make good use of whiteboard space and use legible handwriting?'
    ]
    feedback_questions =
    [
      'What did the interviewee do well?',
      'What could be improved?'
    ]
    technical_questions.each do |question|
      PeerQuestion.create(content: question, category: 'technical')
    end
    professionalism_questions.each do |question|
      PeerQuestion.create(content: question, category: 'professionalism')
    end
    feedback_questions.each do |question|
      PeerQuestion.create(content: question, category: 'feedback')
    end
  end

  def down
    PeerQuestion.destroy_all
  end
end
