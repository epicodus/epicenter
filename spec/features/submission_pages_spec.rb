require 'rails_helper'

feature 'index page' do
  scenario 'lists submissions' do

  end

  scenario 'lists only submissions needing review' do

  end

  scenario 'lists submissions in order of when they were created' do

  end

  context 'within an individual submission' do
    scenario 'shows name of student who submitted' do

    end

    scenario 'shows date of when submission was last updated' do

    end

    scenario 'has link to the github repository' do

    end

    scenario 'has a form for creating a review of this submission' do

    end

    context 'and then creating a review' do
      scenario 'with valid input' do

      end

      scenario 'with invalid input' do

      end
    end
  end
end
