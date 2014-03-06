module Monkeyshines
  module Store
    class KeyStore < Monkeyshines::Store::Base
      # The actual backing store; should respond to #set and #get methods
      attr_accessor :db

      #
      # Executes block once for each element in the whole DB, in whatever order
      # the DB thinks you should see it.
      #
      # Your block will see |key, val|
      #
      # key_store.each do |key, val|
      #   # ... stuff ...
      # end
      #
      def each &block
        db.iterinit
        loop do
          key = db.iternext or break
          val = db[key]
          yield key, val
        end
      end


      # Save the value into the database
      def set(key, val)
        return unless val
        db[key] = val
      end

      alias_method :save, :set
      def get(key)      db[key]  end
      def [](key)       db[key]  end
      def close()       db.close end
      def size()        db.size  end

      #
      # Load from standard command-line options
      #
      # obvs only works when there's just one store
      #
      def self.new_from_command_line cmdline_opts, default_opts={}
        options = default_opts.merge(cmdline_opts)
        store = self.new(options[:store_db])
        store
      end
    end
  end
end
