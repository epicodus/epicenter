class SeedPairIds < ActiveRecord::Migration[5.2]
  def up
    AttendanceRecord.where.not(pair_id: nil).each do |ar|
      pair_ids = []
      pair_ids << ar.pair_id
      pair_ids << ar.pair2_id if ar.pair2_id
      ar.update_columns(pair_ids: pair_ids)
    end
  end

  def down
    AttendanceRecord.where.not(pair_ids: []).each do |ar|
      ar.update_columns(pair_id: ar.pair_ids.first)
      ar.update_columns(pair2_id: ar.pair_ids.last) if ar.pair_ids.count > 1
    end
  end
end
