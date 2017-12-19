class SeedSurvey < ActiveRecord::Migration[5.1]
  def up
    survey = Survey.create(name: "friday survey")

    question1 = SurveyQuestion.create(survey_id: survey.id, number: 1, content: "In general, how well did your teacher help you this week?")
    SurveyOption.create(survey_question_id: question1.id, number: 1, content: "Very Well - I always, or almost always, got the support and help I needed.")
    SurveyOption.create(survey_question_id: question1.id, number: 2, content: "Well - I mostly got the support and help I needed.")
    SurveyOption.create(survey_question_id: question1.id, number: 3, content: "Neutral - My teacher was equally helpful and not helpful. It was 50/50.")
    SurveyOption.create(survey_question_id: question1.id, number: 4, content: "Not well - My teacher was rarely helpful and supportive when I asked for help.")
    SurveyOption.create(survey_question_id: question1.id, number: 5, content: "Not at all - My teacher was never helpful or supportive when I asked for help.")
    SurveyOption.create(survey_question_id: question1.id, number: 6, content: "N/A - I did not ask for help or support on any days this week, so I can't really say.")

    question2 = SurveyQuestion.create(survey_id: survey.id, number: 2, content: "In general, how available was your teacher to you this week?")
    SurveyOption.create(survey_question_id: question2.id, number: 1, content: "Very available. I got their attention pretty quickly when I needed it on most days.")
    SurveyOption.create(survey_question_id: question2.id, number: 2, content: "Available. I generally got their attention easily, although some days there were some delays.")
    SurveyOption.create(survey_question_id: question2.id, number: 3, content: "Equally available and not available. Some days I didn't feel like I got enough attention, or it took a long time.")
    SurveyOption.create(survey_question_id: question2.id, number: 4, content: "Somewhat unavailable. I felt like I didn't get enough attention most days, or it took a very long time.")
    SurveyOption.create(survey_question_id: question2.id, number: 5, content: "Barely available. Most days, I rarely got attention, even when I asked for help.")
    SurveyOption.create(survey_question_id: question2.id, number: 6, content: "N/A - I did not ask for help or support on any days this week, so I can't really say.")

    question3 = SurveyQuestion.create(survey_id: survey.id, number: 3, content: "How clear and easy to follow were this week’s curriculum and in class lessons?")
    SurveyOption.create(survey_question_id: question3.id, number: 1, content: "The lessons were clear and I understood each day's material.")
    SurveyOption.create(survey_question_id: question3.id, number: 2, content: "The lessons were clear, but I don’t fully understand some day’s material.")
    SurveyOption.create(survey_question_id: question3.id, number: 3, content: "This week was a mixed bag. Some lessons were clear, some need improvement.")
    SurveyOption.create(survey_question_id: question3.id, number: 4, content: "The lessons weren’t clear but I was able to grasp the material.")
    SurveyOption.create(survey_question_id: question3.id, number: 5, content: "The lessons weren’t clear and I don’t understand the material on most or all days week’s material.")

    question4 = SurveyQuestion.create(survey_id: survey.id, number: 4, content: "How well did the curriculum and in class lessons this week prepare you for the assignment you just completed?")
    SurveyOption.create(survey_question_id: question4.id, number: 1, content: "The lessons weren’t clear and I don’t understand the material on most or all days week’s material.")
    SurveyOption.create(survey_question_id: question4.id, number: 2, content: "I felt fairly well prepared to complete the assignment.")
    SurveyOption.create(survey_question_id: question4.id, number: 3, content: "So-so. I struggled to complete some areas of the assignment, but not the majority.")
    SurveyOption.create(survey_question_id: question4.id, number: 4, content: "Badly - I struggled to complete many areas of the assignment despite working through the lessons.")
    SurveyOption.create(survey_question_id: question4.id, number: 5, content: "Very Badly - I was unable to complete the assignment despite working through the lessons.")
    SurveyOption.create(survey_question_id: question4.id, number: 6, content: "Can't Say - I completed an open Independent Project that was intentionally not related to the curriculum")

    question5 = SurveyQuestion.create(survey_id: survey.id, number: 5, content: "How did you feel about this week's independent project prompt, generally speaking? Choose the option that matches your experience best.")
    SurveyOption.create(survey_question_id: question5.id, number: 1, content: "An excellent use of my time: This prompt was very motivating. I was able to further explore the tools I learned this week. More like this please!")
    SurveyOption.create(survey_question_id: question5.id, number: 2, content: "A good use of my time. This prompt was motivating and I solidified my knowledge.")
    SurveyOption.create(survey_question_id: question5.id, number: 3, content: "Neutral. This prompt was not motivating, but I solidified my knowledge.")
    SurveyOption.create(survey_question_id: question5.id, number: 4, content: "A not so great use of my time. This prompt was not motivating and I barely improved my skills.")
    SurveyOption.create(survey_question_id: question5.id, number: 5, content: "A bad use of my time. This prompt negatively affected my learning. I was not able to practice the tools we learned this week, OR I completed an Open Independent Project that felt ineffective.")
  end

  def down
    Survey.destroy_all
  end
end
