require 'tokyo_tyrant'
require 'tokyo_tyrant/balancer'

# make sure tokyocabinet and tokyotyrant are installed (cehf recipe)
# make sure ruby-tokyotyrant is installed
# ldconfig
# mkdir -p /data/db/ttyrant
# ttserver -port 12001 /data/db/ttyrant/user_ids.tch#bnum=100000000#opts=l
# ttserver -port 12002 /data/db/ttyrant/screen_names.tch#bnum=100000000#opts=l
# ttserver -port 12003 /data/db/ttyrant/search_ids.tch#bnum=100000000#opts=l
# ttserver -port 12004 /data/db/ttyrant/tweets_parsed.tch#bnum=800000000#opts=l
# ttserver -port 12005 /data/db/ttyrant/users_parsed.tch#bnum=100000000#opts=l


class TokyoTyrant::Balancer::Base
  def initialize(hostnames = [], timeout = 3.0, should_retry = true)
    @servers = hostnames.map do |hostname|
      host, port = hostname.split(':')
      klass.new(host, port.to_i, timeout, should_retry)
    end
    @ring = TokyoTyrant::ConstistentHash.new(servers)
  end

  def close
    @servers.all?{ |server| server.close } rescue nil
  end

end

module TokyoDbConnection
  class TyrantDb
    attr_reader :dataset
    DB_SERVERS = [
      '10.218.47.247',
      '10.218.71.212',
      '10.194.93.123',
      '10.195.77.171',
    ].freeze

    DB_PORTS = {
      :user_ids      => 12001,
      :screen_names  => 12002,
      :search_ids    => 12003,
      :tweets_parsed => 12004,
      :users_parsed  => 12005,
    }

    def initialize dataset
      @dataset = dataset
    end

    def db
      return @db if @db
      port = DB_PORTS[dataset] or raise "Don't know how to reach dataset #{dataset}"
      @db = TokyoTyrant::Balancer::DB.new(DB_SERVERS.map{|s| s+':'+port.to_s})
      # @db = TokyoTyrant::DB.new(DB_SERVERS.first, port.to_i)
      @db
    end

    def [](*args) ; db[*args] ; end

    #
    # Insert into the cassandra database with default settings
    #
    def insert key, value
      begin
        db.putnr(key, value)
      rescue StandardError => e ; handle_error("Insert #{[key, value].inspect}", e); end
    end

    def insert_array key, value
      insert(key, value.join(','))
    end

    def get *args
      begin
        db.get(*args)
      rescue StandardError => e ; handle_error("Fetch #{args.inspect}", e); end
    end

    def handle_error action, e
      warn "#{action} failed: #{e} #{e.backtrace.join("\t")}" ;
      invalidate!
      sleep 0.2
    end

    def invalidate!
      (@db && @db.close) or warn "Couldn't close #{@db.inspect}"
      @db = nil
    end
  end
end
