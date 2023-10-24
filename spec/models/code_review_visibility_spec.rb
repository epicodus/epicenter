describe CodeReviewVisibility, :stub_mailgun do
  it { should belong_to :student }
  it { should belong_to :code_review }

  let(:evening_visible_date) { DateTime.current.beginning_of_week(:sunday) + 4.days + 17.hours }
  let(:ft_visible_date) { DateTime.current.beginning_of_week(:sunday) + 5.days + 8.hours }
  let(:visible_date) { nil }
  let(:parttime) { false }
  let(:course) { FactoryBot.create(:course, parttime: parttime) }
  let(:student) { FactoryBot.create(:student, course: course) }
  let(:code_review) { FactoryBot.create(:code_review, course: student.course, visible_date: visible_date) }

  it 'validates uniqueness of student_id scoped to code_review_id' do
    expect(code_review.code_review_visibility_for(student)).to be_valid
    expect(FactoryBot.build(:code_review_visibility, student: student, code_review: code_review)).not_to be_valid
  end

  describe 'sets initial visibility' do
    context 'when code review has no visible_date' do
      let(:visible_date) { nil }
      it 'sets initial visibility when no visible_date' do
        expect(code_review.code_review_visibility_for(student).always_visible).to eq true
      end
    end

    context 'when code_review has a visible_date' do
      let(:visible_date) { ft_visible_date }
      it 'sets initial visibility when visible_date' do
        crv = code_review.code_review_visibility_for(student)
        expect(crv.visible_start).to eq visible_date
        expect(crv.always_visible).to eq nil
      end
    end
  end

  describe 'sets visible_end' do
    context 'when code review has no visible_date' do
      let(:visible_date) { nil }
      it 'does not set visible_end' do
        crv = code_review.code_review_visibility_for(student)
        expect(crv.visible_end).to eq nil
      end
    end

    context 'when visible_start has been set' do
      context 'when course is evening' do
        let(:parttime) { true }
        let(:visible_date) { evening_visible_date }
        it 'sets visible_end' do
          allow_any_instance_of(Course).to receive(:evening?).and_return(true)
          crv = code_review.code_review_visibility_for(student)
          expect(crv.visible_end).to eq evening_visible_date.in_time_zone.beginning_of_week(:sunday) + 7.days + 9.hours
        end
      end

      context 'when course is parttime daytime' do
        let(:parttime) { true }
        let(:visible_date) { ft_visible_date }
        it 'sets visible_end' do
          crv = code_review.code_review_visibility_for(student)
          expect(crv.visible_end).to eq ft_visible_date.in_time_zone.beginning_of_week(:sunday) + 8.days + 8.hours
        end
      end

      context 'when course is fulltime' do
        let(:parttime) { false }
        let(:visible_date) { ft_visible_date }
        it 'sets visible_end' do
          crv = code_review.code_review_visibility_for(student)
          expect(crv.visible_end).to eq ft_visible_date.in_time_zone.beginning_of_week(:sunday) + 8.days + 8.hours
        end
      end
    end

    context 'when visible_start is modified' do
      let(:visible_date) { ft_visible_date }
      it 'sets visible_end' do
        crv = code_review.code_review_visibility_for(student)
        crv.update(visible_start: ft_visible_date + 1.week)
        expect(crv.visible_end).to eq (ft_visible_date.in_time_zone.beginning_of_week(:sunday) + 15.days).change(hour: 8)
      end
    end
  end

  describe 'visible?' do
    context 'before visible_start' do
      let(:visible_date) { ft_visible_date }
      it 'returns false' do
        travel_to ft_visible_date - 1.day do
          crv = code_review.code_review_visibility_for(student)
          expect(crv.visible?).to eq false
        end
      end
    end

    context 'after visible_end' do
      let(:visible_date) { ft_visible_date }
      it 'returns false' do
        travel_to ft_visible_date + 9.days do
          crv = code_review.code_review_visibility_for(student)
          expect(crv.visible?).to eq false
        end
      end
    end

    context 'between visible_start and visible_end' do
      let(:visible_date) { ft_visible_date }
      it 'returns true' do
        travel_to ft_visible_date do
          crv = code_review.code_review_visibility_for(student)
          expect(crv.visible?).to eq true
        end
      end
    end

    context 'when expectations are met' do
      let(:visible_date) { ft_visible_date }
      let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }
      let!(:review) { FactoryBot.create(:passing_review, submission: submission) }
      it 'returns false' do
        travel_to ft_visible_date do
          crv = code_review.code_review_visibility_for(student)
          expect(crv.visible?).to eq false
        end
      end
    end
    
    context 'when special permission is granted' do
      let(:visible_date) { ft_visible_date }
      it 'returns true' do
        travel_to ft_visible_date - 1.day do
          crv = code_review.code_review_visibility_for(student)
          crv.update(special_permission: true)
          expect(crv.visible?).to eq true
        end
      end
    end

    context 'when always_visible' do
      let(:visible_date) { nil }
      it 'returns true' do
        crv = code_review.code_review_visibility_for(student)
        expect(crv.visible?).to eq true
      end
    end
  end

  describe '#past_due?' do
    let(:crv) { code_review.code_review_visibility_for(student) }

    context 'when always_visible' do
      let(:visible_date) { nil }

      it 'returns false' do
        allow_any_instance_of(CodeReviewVisibility).to receive(:visible_end).and_return(DateTime.current - 1.day)
        expect(crv.past_due?).to eq false
      end
    end

    context 'when not always_visible' do
      let(:visible_date) { ft_visible_date }

      context 'when past due' do
        it 'returns true' do
          allow_any_instance_of(CodeReviewVisibility).to receive(:visible_end).and_return(DateTime.current - 1.day)
          expect(crv.past_due?).to eq true
        end
      end

      context 'when not past due' do
        it 'returns false' do
          allow_any_instance_of(CodeReviewVisibility).to receive(:visible_end).and_return(DateTime.current + 1.day)
          expect(crv.past_due?).to eq false
        end
      end
    end
  end
end
