require 'tokyotyrant'
require 'tyrant_rdb_key_store'
module Monkeyshines
  module Store
    #
    # Implementation of KeyStore with a Local TokyoCabinet Table database (RDBTBL)
    #
    class TyrantRdbKeyStore < TyrantRdbKeyStore Monkeyshines::Store::KeyStore

      def db
        return @db if @db
        @db ||= TokyoTyrant::RDBTBL.new
        @db.open(db_host, db_port) or raise("Can't open DB #{db_host}:#{db_port}. Pass in host:port' #{@db.ecode}: #{@db.errmsg(@db.ecode)}")
        @db
      end

    end #class
  end
end

