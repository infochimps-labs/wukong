Settings.define :cassandra_hosts,    :default => '127.0.0.1:9160', :type => Array, :description => 'Comma-delimited list of hostname:port addresses for the Cassandra database holding Twitter API objects'
Settings.define :cassandra_keyspace, :default => 'soc_net_tw',                     :description => 'Cassandra keyspace for Twitter objects'

module Wukong
  module Store
    module CassandraStore
      autoload :StructLoader, 'wukong/store/cassandra/struct_loader'
    end
  end
end
