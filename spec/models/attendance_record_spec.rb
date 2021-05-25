describe AttendanceRecord do
  describe 'validates uniqueness of student_id per day' do
    it do
      student = FactoryBot.create(:student, :with_course)
      travel_to student.course.start_date do
        FactoryBot.create(:attendance_record, student: student)
        should validate_uniqueness_of(:student_id).scoped_to(:date)
      end
    end
  end

  context 'before create' do
    it 'sets the date property to the current date' do
      student = FactoryBot.create(:student, :with_course)
      travel_to student.course.start_date do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        expect(attendance_record.date).to eq(Time.zone.now.to_date)
      end
    end
  end

  describe 'adds station to student record if entered' do
    let(:first_user) { FactoryBot.create(:student, :with_course) }
    let(:second_user) { FactoryBot.create(:student, :with_course) }
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
      student = FactoryBot.create(:student, :with_course)
      first_attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      second_attendance_record = FactoryBot.build(:attendance_record, student: student, date: student.course.start_date)
      expect(second_attendance_record.valid?).to eq false
    end

    it 'allows multiple users to check in on a single day' do
      first_user = FactoryBot.create(:student, :with_course)
      second_user = FactoryBot.create(:student, :with_course)
      FactoryBot.create(:attendance_record, student: first_user, date: first_user.course.start_date)
      second_attendance_record = FactoryBot.build(:attendance_record, student: second_user, date: second_user.course.start_date)
      expect(second_attendance_record.valid?).to eq true
    end
  end

  describe '.today' do
    it 'returns all the attendance records for today' do
      student = FactoryBot.create(:student, :with_course)
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      travel_to student.course.start_date + 1.day do
        current_attendance_record = FactoryBot.create(:attendance_record, student: student)
        expect(AttendanceRecord.today).to eq [current_attendance_record]
      end
    end
  end

  describe '.paired_only' do
    it 'returns only attendance records with any pairings' do
      student = FactoryBot.create(:student, :with_course)
      pair = FactoryBot.create(:student, :with_course)
      FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, pairings_attributes: [pair_id: pair.id])
      FactoryBot.create(:attendance_record, student: student, date: student.course.end_date)
      expect(student.attendance_records.count).to eq 2
      expect(student.attendance_records.paired_only.count).to eq 1
    end
  end

  describe '.all_before_2021_and_paired_only_starting_2021' do
    it 'returns all records from before 2021 but only records with pairings starting 2021' do
      old_course = FactoryBot.create(:course, class_days: [Date.parse('2020-01-06'), Date.parse('2020-01-07')])
      new_course = FactoryBot.create(:course, class_days: [Date.parse('2021-01-04'), Date.parse('2021-01-05')])
      student = FactoryBot.create(:student, courses: [old_course, new_course])
      pair = FactoryBot.create(:student, courses: [old_course, new_course])
      FactoryBot.create(:attendance_record, student: student, date: old_course.class_days.first, pairings_attributes: [pair_id: pair.id])
      FactoryBot.create(:attendance_record, student: student, date: old_course.class_days.last)
      FactoryBot.create(:attendance_record, student: student, date: new_course.class_days.first, pairings_attributes: [pair_id: pair.id])
      FactoryBot.create(:attendance_record, student: student, date: new_course.class_days.last)
      expect(student.attendance_records.count).to eq 4
      expect(student.attendance_records.all_before_2021_and_paired_only_starting_2021.count).to eq 3
    end

    it 'includes all friday records regardless of pairing status' do
      course = FactoryBot.create(:course, class_days: [Date.parse('2021-01-04'), Date.parse('2021-01-08')])
      student = FactoryBot.create(:student, courses: [course])
      FactoryBot.create(:attendance_record, student: student, date: course.class_days.last)
      expect(student.attendance_records.count).to eq 1
      expect(student.attendance_records.all_before_2021_and_paired_only_starting_2021.count).to eq 1
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

  describe '#tardy', :dont_stub_class_times do
    context 'for full-time student' do
      let(:course) { FactoryBot.create(:course_with_class_times) }
      let(:student) { FactoryBot.create(:student, courses: [course]) }
      let(:start_time) { course.start_date.in_time_zone(course.office.time_zone) + course.start_time(course.start_date).split(':').first.to_i.hours }

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

    context 'for part-time student' do
      context 'on a weekday' do
        let(:course) { FactoryBot.create(:pt_course_with_class_times) }
        let(:student) { FactoryBot.create(:student, courses: [course]) }
        let(:start_time) { course.start_date.in_time_zone(course.office.time_zone) + course.start_time(course.start_date).split(':').first.to_i.hours }

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

      context 'on a sunday' do
        let(:course) { FactoryBot.create(:pt_course_with_class_times) }
        let(:student) { FactoryBot.create(:student, courses: [course]) }
        let(:start_time) { ActiveSupport::TimeZone[course.office.time_zone].parse(course.start_date.end_of_week.to_s + ' ' + course.start_time(course.start_date.end_of_week)) }
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
    end
  end

  describe '#left_early', :dont_stub_class_times do
    context 'for full-time students' do
      let(:course) { FactoryBot.create(:course_with_class_times) }
      let(:student) { FactoryBot.create(:student, courses: [course]) }
      let(:end_time) { course.start_date.in_time_zone(course.office.time_zone) + course.end_time(course.start_date).split(':').first.to_i.hours }

      it 'is true by default' do
        travel_to end_time do
          attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
          expect(attendance_record.left_early).to eq true
        end
      end

      it 'is true when a student leaves early mon-thu' do
        travel_to end_time - 20.minutes do
          shirker_attendance_record = FactoryBot.create(:attendance_record, student: student)
          shirker_attendance_record.update({:signing_out => true})
          expect(shirker_attendance_record.left_early).to eq true
        end
      end

      it 'is false when a student leaves after the alloted end time' do
        travel_to end_time + 1.minute do
          diligent_attendance_record = FactoryBot.create(:attendance_record, student: student)
          diligent_attendance_record.update({:signing_out => true})
          expect(diligent_attendance_record.left_early).to eq false
        end
      end

      it 'is false when a student leaves less than 15 minutes before the alloted end time' do
        travel_to end_time - 14.minutes do
          diligent_attendance_record = FactoryBot.create(:attendance_record, student: student)
          diligent_attendance_record.update({:signing_out => true})
          expect(diligent_attendance_record.left_early).to eq false
        end
      end

      it 'is true when a student leaves more than 30 minutes after the alloted end time' do
        travel_to end_time + 32.minutes do
          late_signer_out_attendance_record = FactoryBot.create(:attendance_record, student: student)
          late_signer_out_attendance_record.update({:signing_out => true})
          expect(late_signer_out_attendance_record.left_early).to eq true
        end
      end
    end

    context 'for part-time student' do
      context 'on a weekday' do
        let(:course) { FactoryBot.create(:pt_course_with_class_times) }
        let(:student) { FactoryBot.create(:student, courses: [course]) }
        let(:end_time) { course.start_date.in_time_zone(course.office.time_zone) + course.end_time(course.start_date).split(':').first.to_i.hours }

        it 'is true when a part-time student leaves early' do
          travel_to end_time - 21.minute do
            shirker_attendance_record = FactoryBot.create(:attendance_record, student: student)
            shirker_attendance_record.update({:signing_out => true})
            expect(shirker_attendance_record.left_early).to eq true
          end
        end

        it 'is true when a part-time student leaves long after end time' do
          travel_to end_time + 1.hour do
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
      context 'on a sunday' do
        let(:course) { FactoryBot.create(:pt_course_with_class_times) }
        let(:student) { FactoryBot.create(:student, courses: [course]) }
        let(:end_time) { ActiveSupport::TimeZone[course.office.time_zone].parse(course.start_date.end_of_week.to_s + ' ' + course.end_time(course.start_date.end_of_week)) }

        it 'is true when a part-time student leaves early' do
          travel_to end_time - 21.minute do
            shirker_attendance_record = FactoryBot.create(:attendance_record, student: student)
            shirker_attendance_record.update({:signing_out => true})
            expect(shirker_attendance_record.left_early).to eq true
          end
        end

        it 'is true when a part-time student leaves long after end time' do
          travel_to end_time + 1.hour do
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
    end
  end

  describe '#sign_out' do
    it 'sets time when a student signs out' do
      student = FactoryBot.create(:student, :with_course)
      attendance_record = FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
      attendance_record.update({:signing_out => true})
      expect(attendance_record.signed_out_time.min).to eq Time.now.min
    end
  end

  describe '#status' do
    let(:student) { FactoryBot.create(:student, :with_course) }

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
      student = FactoryBot.create(:student, :with_course)
      travel_to student.course.start_date.beginning_of_day + 8.hours do
        attendance_record = FactoryBot.create(:attendance_record, student: student)
        expect(AttendanceRecord.first).to eq attendance_record
      end
    end

    it 'fails to create attendance record when course not in session' do
      student = FactoryBot.create(:student, :with_course)
      travel_to student.course.start_date.beginning_of_day - 1.week + 8.hours do
        attendance_record = FactoryBot.build(:attendance_record, student: student)
        attendance_record.save
        expect(attendance_record.errors.full_messages.first).to eq 'Attendance record sign in not required.'
      end
    end
  end
end
