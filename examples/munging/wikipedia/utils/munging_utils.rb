# encoding:UTF-8
module MungingUtils
  def time_columns_from_time(time)
    columns = []
    columns << "%04d%02d%02d" % [time.year, time.month, time.day]
    columns << "%02d%02d%02d" % [time.hour, time.min, time.sec]
    columns << time.to_i
    columns << time.wday
    return columns
  end
end
