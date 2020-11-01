describe AttendanceRecord do
  describe 'validates uniqueness of student_id per day' do
    it do
      student = FactoryBot.create(:student)
      travel_to student.course.start_date do
        FactoryBot.create(:attendance_record, student: student)
        should validate_uniqueness_of(:student_id).scoped_to(:date)
      end
    end
  end

  context 'before create' do
    it 'sets the date property to the current date' do
      student = FactoryBot.create(:student)
      travel_to student.course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        expect(attendance_record.date).to eq(Time.zone.now.to_date)
      end
    end
  end

  describe 'adds station to student record if entered' do
    let(:first_user) { FactoryBot.create(:student) }
    let(:second_user) { FactoryBot.create(:student) }
    let(:first_attendance_record) { FactoryBot.create(:attendance_record, student: first_user, date: first_user.course.start_date) }
    let(:second_attendance_record) { FactoryBot.create(:attendance_record, student: second_user, date: second_user.course.start_date) }

    it 'adds station if entered on pair signin' do
      first_attendance_record.station = "1A"
      second_attendance_record.station = "1A"
      expect(first_attendance_record.station).to eq "1A"
      expect(second_attendance_record.station).to eq "1A"
    end

    it 'allows login even if no station entered' do
      expect(first_attendance_record.valid?).to eq true
      expect(second_attendance_record.valid?).to eq true
    end
  end

  describe 'uniqueness validation for users' do
    it 'validates that an attendance record for a student has not already been created for today' do
      student = FactoryBot.create(:student)
      first_attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      second_attendance_record = FactoryBot.build(:attendance_record, student: student, date: student.course.start_date)
      expect(second_attendance_record.valid?).to eq false
    end

    it 'allows multiple users to check in on a single day' do
      first_user = FactoryBot.create(:student)
      second_user = FactoryBot.create(:student)
      FactoryBot.create(:attendance_record, student: first_user, date: first_user.course.start_date)
      second_attendance_record = FactoryBot.build(:attendance_record, student: second_user, date: second_user.course.start_date)
      expect(second_attendance_record.valid?).to eq true
    end
  end

  describe '.today' do
    it 'returns all the attendance records for today' do
      student = FactoryBot.create(:student)
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      travel_to student.course.start_date + 1.day do
        current_attendance_record = FactoryBot.create(:attendance_record)
        expect(AttendanceRecord.today).to eq [current_attendance_record]
      end
    end
  end

  describe '#todays_totals_for' do
    let(:course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, course: course) }
    let!(:student_2) { FactoryBot.create(:student, course: course) }

    it 'returns number of on time attendance records for today for a particular course' do
      FactoryBot.create(:on_time_attendance_record, student: student, date: student.course.start_date)
      FactoryBot.create(:on_time_attendance_record, student: student_2, date: student_2.course.start_date)
      travel_to student.course.start_date do
        expect(AttendanceRecord.todays_totals_for(course, :on_time)).to eq 2
      end
    end

    it 'returns number of tardy attendance records for today for a particular course' do
      FactoryBot.create(:on_time_attendance_record, student: student, date: student.course.start_date)
      FactoryBot.create(:tardy_attendance_record, student: student_2, date: student_2.course.start_date)
      travel_to student.course.start_date do
        expect(AttendanceRecord.todays_totals_for(course, :tardy)).to eq 1
      end
    end

    it 'returns number of left early attendance records for today for a particular course' do
      FactoryBot.create(:left_early_attendance_record, student: student, date: student.course.start_date)
      FactoryBot.create(:tardy_attendance_record, student: student_2, date: student_2.course.start_date)
      travel_to student.course.start_date do
        expect(AttendanceRecord.todays_totals_for(course, :left_early)).to eq 1
      end
    end

    it 'returns number of absences for today for a particular course' do
      FactoryBot.create(:on_time_attendance_record, student: student, date: student.course.start_date)
      travel_to student.course.start_date do
        expect(AttendanceRecord.todays_totals_for(course, :absent)).to eq 1
      end
    end
  end

  describe '#tardy' do
    context 'for full-time student' do
      let(:student) { FactoryBot.create(:student) }
      let(:start_time) { student.course.start_date.in_time_zone(student.course.office.time_zone) + student.course.the_start_time.split(':').first.to_i.hours }

      it 'is true if the student checks in after the start of class' do
        travel_to start_time + 30.minute do
          tardy_attendance_record = FactoryBot.create(:attendance_record, student: student)
          expect(tardy_attendance_record.tardy).to eq true
        end
      end

      it 'is false if the student checks in before the start of class' do
        travel_to start_time - 1.minute do
          on_time_attendance_record = FactoryBot.create(:attendance_record, student: student)
          expect(on_time_attendance_record.tardy).to eq false
        end
      end
    end

    context 'for part-time intro student' do
      let(:student) { FactoryBot.create(:part_time_student) }
      let(:start_time) { student.course.start_date.in_time_zone(student.course.office.time_zone) + student.course.the_start_time.split(':').first.to_i.hours }

      it 'is true if the part-time student checks in after the start of class' do
        travel_to start_time + 30.minute do
          tardy_attendance_record = FactoryBot.create(:attendance_record, student: student)
          expect(tardy_attendance_record.tardy).to eq true
        end
      end

      it 'is false if the part-time student checks in before the start of class' do
        travel_to start_time - 1.minute do
          on_time_attendance_record = FactoryBot.create(:attendance_record, student: student)
          expect(on_time_attendance_record.tardy).to eq false
        end
      end
    end

    context 'for part-time track student' do
      let(:student) { FactoryBot.create(:part_time_track_student_with_cohort) }
      let(:start_time) { student.course.start_date.in_time_zone(student.course.office.time_zone) + student.course.the_start_time.split(':').first.to_i.hours }

      context 'on a weekday' do
        it 'is true if checks in after the start of class' do
          travel_to start_time + 30.minute do
            tardy_attendance_record = FactoryBot.create(:attendance_record, student: student)
            expect(tardy_attendance_record.tardy).to eq true
          end
        end

        it 'is false if checks in before the start of class' do
          travel_to start_time - 1.minute do
            on_time_attendance_record = FactoryBot.create(:attendance_record, student: student)
            expect(on_time_attendance_record.tardy).to eq false
          end
        end
      end

      context 'on Sunday' do
        it 'is true if checks in after the start of class' do
          travel_to start_time.beginning_of_week + 6.days + 10.hours + 30.minutes do
            tardy_attendance_record = FactoryBot.create(:attendance_record, student: student)
            expect(tardy_attendance_record.tardy).to eq true
          end
        end

        it 'is false if checks in before the start of class' do
          travel_to start_time.beginning_of_week + 6.days + 9.hours - 1.minute do
            on_time_attendance_record = FactoryBot.create(:attendance_record, student: student)
            expect(on_time_attendance_record.tardy).to eq false
          end
        end
      end
    end
  end

  describe '#left_early' do
    context 'for full-time students' do
      let(:student) { FactoryBot.create(:student) }
      let(:end_time) { student.course.start_date.in_time_zone(student.course.office.time_zone) + student.course.the_end_time.split(':').first.to_i.hours }

      it 'is true by default' do
        attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
        expect(attendance_record.left_early).to eq true
      end

      it 'is true when a student leaves early mon-thu' do
        travel_to student.course.start_date.in_time_zone(student.course.office.time_zone) + 17.hours - 21.minute do
          shirker_attendance_record = FactoryBot.create(:attendance_record)
          shirker_attendance_record.update({:signing_out => true})
          expect(shirker_attendance_record.left_early).to eq true
        end
      end

      it 'is false when a student leaves after the alloted end time' do
        travel_to end_time + 1.minute do
          diligent_attendance_record = FactoryBot.create(:attendance_record)
          diligent_attendance_record.update({:signing_out => true})
          expect(diligent_attendance_record.left_early).to eq false
        end
      end

      it 'is false when a student leaves less than 15 minutes before the alloted end time' do
        travel_to end_time - 14.minutes do
          diligent_attendance_record = FactoryBot.create(:attendance_record)
          diligent_attendance_record.update({:signing_out => true})
          expect(diligent_attendance_record.left_early).to eq false
        end
      end

      it 'is true when a student leaves more than 30 minutes after the alloted end time' do
        travel_to end_time + 32.minutes do
          late_signer_out_attendance_record = FactoryBot.create(:attendance_record)
          late_signer_out_attendance_record.update({:signing_out => true})
          expect(late_signer_out_attendance_record.left_early).to eq true
        end
      end
    end

    context 'for part-time intro students' do
      let(:student) { FactoryBot.create(:part_time_student) }
      let(:end_time) { student.course.start_date.in_time_zone(student.course.office.time_zone) + student.course.the_end_time.split(':').first.to_i.hours }

      it 'is true when a part-time student leaves early' do
        travel_to end_time - 21.minute do
          shirker_attendance_record = FactoryBot.create(:attendance_record, student: student)
          shirker_attendance_record.update({:signing_out => true})
          expect(shirker_attendance_record.left_early).to eq true
        end
      end

      it 'is false when a part-time student leaves after the alloted end time' do
        travel_to end_time + 1.minute do
          diligent_attendance_record = FactoryBot.create(:attendance_record, student: student)
          diligent_attendance_record.update({:signing_out => true})
          expect(diligent_attendance_record.left_early).to eq false
        end
      end
    end

    context 'for part-time js/react track student' do
      let(:student) { FactoryBot.create(:part_time_track_student_with_cohort) }
      let(:end_time) { student.course.start_date.in_time_zone(student.course.office.time_zone) + student.course.the_end_time.split(':').first.to_i.hours }

      context 'on a weekday' do
        it 'is false when leaves after end of class' do
          travel_to end_time - 1.hour do
            FactoryBot.create(:attendance_record, student: student)
          end
          travel_to end_time + 1.minute do
            AttendanceRecord.last.update({:signing_out => true})
            expect(AttendanceRecord.last.left_early).to eq false
          end
        end

        it 'is true when leaves early' do
          travel_to end_time - 1.hour do
            FactoryBot.create(:attendance_record, student: student)
          end
          travel_to end_time - 30.minutes do
            AttendanceRecord.last.update({:signing_out => true})
            expect(AttendanceRecord.last.left_early).to eq true
          end
        end
      end
    end
  end

  describe '#sign_out' do
    it 'sets time when a student signs out' do
      student = FactoryBot.create(:student)
      attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      attendance_record.update({:signing_out => true})
      expect(attendance_record.signed_out_time.min).to eq Time.now.min
    end
  end

  describe '#status' do
    let(:student) { FactoryBot.create(:student) }

    it 'reports status as on time' do
      attendance_record = FactoryBot.create(:attendance_record, tardy: false, left_early: false, student: student, date: student.course.start_date)
      expect(attendance_record.status).to eq "On time"
    end

    it 'reports status as tardy' do
      attendance_record = FactoryBot.create(:attendance_record, tardy: true, left_early: false, student: student, date: student.course.start_date)
      expect(attendance_record.status).to eq "Tardy"
    end

    it 'reports status as left early' do
      attendance_record = FactoryBot.create(:attendance_record, tardy: false, left_early: true, student: student, date: student.course.start_date)
      expect(attendance_record.status).to eq "Left early"
    end

    it 'reports status as tardy and left early' do
      attendance_record = FactoryBot.create(:attendance_record, tardy: true, left_early: true, student: student, date: student.course.start_date)
      expect(attendance_record.status).to eq "Tardy and Left early"
    end
  end

  describe '#course_in_session?' do
    it 'creates attendance record when course in session' do
      student = FactoryBot.create(:student)
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        expect(AttendanceRecord.first).to eq attendance_record
      end
    end

    it 'fails to create attendance record when course not in session' do
      student = FactoryBot.create(:student)
      travel_to student.course.start_date.beginning_of_day - 1.week + 8.hours do
        attendance_record = FactoryBot.build(:attendance_record, student: student)
        attendance_record.save
        expect(attendance_record.errors.full_messages.first).to eq 'Attendance record sign in not required.'
      end
    end
  end
end
