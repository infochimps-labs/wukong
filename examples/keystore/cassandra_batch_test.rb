#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'

# An example (and test) of streaming batches of data into distributed cassandra db
# Stream in whatever you like that has a key and value. Notice that you must
# have already defined a column space called 'Cruft' in storage-conf.xml as well
# as a column family called 'OhBaby'

class Mapper < Wukong::Streamer::CassandraStreamer

  # you must redefine the column space, batch size, and db-seeds  or they will
  # be defaults. For testing on local machine simply seed db with 127.0.0.1:9160

  def initialize *args
    self.column_space = 'Cruft'
    self.batch_size = 100
    self.db_seeds = "127.0.0.1:9160"
    super(*args)
    @iter = 0
  end

  def process key, value, *_, &blk
    insert_into_db(key, value)
    yield [key, value] if (@iter %10 == 0)
  end

  # you must specify the column family, key, and value here
  def insert_into_db key, value
    @iter += 1
    cassandra_db.insert(:OhBaby, key, {"value" => value}, :consistency => Cassandra::Consistency::ANY) unless key.blank?
  end
end

#
# Executes the script
#
Wukong::Script.new(
  Mapper,
  nil
).run
