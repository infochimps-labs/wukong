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

  def warn_record(desc, record=nil)
    record_info = MultiJson.encode(record)[0..1000] rescue "(unencodeable record) #{record.inspect[0..100]}"
    Log.warn [desc, record_info].join("\t")
    nil
  end
end

MatchData.class_eval do
  def as_hash
    Hash[ names.map{|name| [name, self[name]] } ]
  end
end
