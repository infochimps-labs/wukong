# this is necessary since you typically only want ONE db connection floating
# around.
require 'cassandra' ; include Cassandra::Constants
module Wukong
  module Keystore

    def db_insert *args
      columns = args.last
      columns.compact!
      columns.each{|k,v| columns[k] = v.to_s}
      args << {:consistency => Cassandra::Consistency::ANY}
      cassandra_db.insert(*args)
    end

    def db_get *args
      result = cassandra_db.get(*args)
    end

  end
end
