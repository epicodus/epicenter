Rails.application.configure do
  config.holidays = ['2017-01-16', '2017-05-29', '2017-07-04', '2017-09-04', '2017-11-10', '2018-01-01', '2018-01-15', '2018-05-28', '2018-07-04', '2018-09-03', '2018-11-12', '2018-12-31', '2019-01-01', '2019-01-21', '2019-05-27', '2019-07-04', '2019-09-02', '2019-11-11', '2020-01-20', '2020-05-25', '2020-07-03', '2020-09-07', '2020-11-11', '2020-12-25', '2021-01-01', '2021-01-18', '2021-05-31', '2021-07-05', '2021-09-06', '2021-11-11', '2021-12-26', '2022-01-17', '2022-05-30', '2022-06-20', '2022-07-04', '2022-09-05', '2022-11-11', '2022-12-25', '2023-01-02', '2023-01-16', '2023-05-29', '2023-06-19', '2023-07-04', '2023-09-04', '2023-11-10', '2024-01-01', '2024-01-15', '2024-05-27', '2024-06-19', '2024-07-04', '2024-09-02', '2024-11-11']
  config.holiday_weeks = ['2017-11-20', '2017-12-25', '2018-11-19', '2018-12-24', '2019-11-25', '2019-12-23', '2019-12-30', '2020-11-23', '2020-12-28', '2021-11-22', '2021-12-27', '2022-11-21', '2022-12-26', '2023-11-20', '2023-12-25', '2024-11-25', '2024-12-23']
  # config.active_record.yaml_column_permitted_classes = [Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]
  ActiveRecord::Base.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]
end