require 'tokyo_tyrant'
require 'tokyo_tyrant/balancer'

# -- Installing
#    make sure tokyocabinet and tokyotyrant are installed (cehf recipe)
#    make sure ruby-tokyotyrant is installed
#    ldconfig
#    mkdir -p /data/db/ttyrant /var/run/tyrant /var/log/tyrant
#
# -- Starting
#    ttserver -port 12001 -thnum 96 -tout 3 -pid /var/run/tyrant/screen_names.pid -kl -log /var/log/tyrant/user_ids.tch      '/data/db/ttyrant/user_ids.tch#bnum=100000000#opts=l#rcnum=50000#xmsiz=268435456'
#    ttserver -port 12002 -thnum 96 -tout 3 -pid /var/run/tyrant/screen_names.pid -kl -log /var/log/tyrant/screen_names.tch  '/data/db/ttyrant/screen_names.tch#bnum=100000000#opts=l#rcnum=50000#xmsiz=268435456'
#    ttserver -port 12003 -thnum 96 -tout 3 -pid /var/run/tyrant/screen_names.pid -kl -log /var/log/tyrant/search_ids.tch    '/data/db/ttyrant/search_ids.tch#bnum=100000000#opts=l#rcnum=50000#xmsiz=268435456'
#    ttserver -port 12004 -thnum 96 -tout 3 -pid /var/run/tyrant/screen_names.pid -kl -log /var/log/tyrant/tweets_parsed.tch '/data/db/ttyrant/tweets_parsed.tch#bnum=800000000#opts=l#rcnum=50000#xmsiz=268435456'
#    ttserver -port 12005 -thnum 96 -tout 3 -pid /var/run/tyrant/screen_names.pid -kl -log /var/log/tyrant/users_parsed.tch  '/data/db/ttyrant/users_parsed.tch#bnum=100000000#opts=l#rcnum=50000#xmsiz=268435456'
#
# -- Monitoring
#      tcrmgr inform -port $port -st $hostname
#    active conns:
#      lsof  -i | grep ttserver | wc -l
#      netstat -a -W | grep ':120' | ruby -ne 'puts $_.split(/ +/)[3 .. 4].join("\t")' | sort | cut -d: -f1-2 | uniq -c | sort -n
#    use db.rnum for most lightweight ping method
#
# -- Tuning
#    http://korrespondence.blogspot.com/2009/09/tokyo-tyrant-tuning-parameters.html
#    http://capttofu.livejournal.com/23381.html
#    http://groups.google.com/group/tokyocabinet-users/browse_thread/thread/5a46ee04006a791c#
#    opts     "l" of large option (the size of the database can be larger than 2GB by using 64-bit bucket array.), "d" of Deflate option (each record is compressed with Deflate encoding), "b" of BZIP2 option, "t" of TCBS option
#    bnum     number of elements of the bucket array. If it is not more than 0, the default value is specified. The default value is 131071 (128K). Suggested size of the bucket array is about from 0.5 to 4 times of the number of all records to be stored.
#    rcnum    maximum number of records to be cached. If it is not more than 0, the record cache is disabled. It is disabled by default.
#    xmsiz    size of the extra mapped memory. If it is not more than 0, the extra mapped memory is disabled. The default size is 67108864 (64MB).
#    apow     size of record alignment by power of 2. If it is negative, the default value is specified. The default value is 4 standing for 2^4=16.
#    fpow     maximum number of elements of the free block pool by power of 2. If it is negative, the default value is specified. The default value is 10 standing for 2^10=1024.
#    dfunit   unit step number of auto defragmentation. If it is not more than 0, the auto defragmentation is disabled. It is disabled by default.
#    mode     "w" of writer, "r" of reader,"c" of creating,"t" of truncating ,"e" of no locking,"f" of non-blocking lock
#
# -- Links
#    http://1978th.net/tokyocabinet/spex-en.html
#    http://groups.google.com/group/tokyocabinet-users/browse_thread/thread/3bd2a93322c09eec#


class TokyoTyrant::Balancer::Base
  def initialize(hostnames = [], timeout = 20.0, should_retry = true)
    @servers = hostnames.map do |hostname|
      host, port = hostname.split(':')
      klass.new(host, port.to_i, timeout, should_retry)
    end
    # Yes this IS a typo, no DO NOT fix it because it goes deep...
    @ring = TokyoTyrant::ConstistentHash.new(servers)
  end

  def close
    @servers.all?{ |server| server.close rescue nil}
  end

end

module TokyoDbConnection
  class TyrantDb
    attr_reader :dataset
    DB_SERVERS = [
      '10.218.47.247',
      '10.194.93.123',
      '10.195.77.171',
    ].freeze unless defined?(TokyoDbConnection::TyrantDb::DB_SERVERS)

    DB_PORTS = {
      :user_ids      => 12001,
      :screen_names  => 12002,
      :search_ids    => 12003,
      :tweets_parsed => 12004,
      :users_parsed  => 12005,
    } unless defined?(TokyoDbConnection::TyrantDb::DB_PORTS)

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

    def [](*args)      ; db[*args]        ; end
    def size(*args)    ; db.size(*args)   ; end
    def vanish!(*args) ; db.vanish(*args) ; end

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
    end

    def invalidate!
      (@db && @db.close) or warn "Couldn't close #{@db.inspect}"
      @db = nil
      sleep 2
    end
  end
end
