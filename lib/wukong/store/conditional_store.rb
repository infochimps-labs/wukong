module Monkeyshines
  module Store
    class ConditionalStore < Monkeyshines::Store::Base
      attr_accessor :options, :cache, :store, :misses

      DEFAULT_OPTIONS = {
        :cache => { :type => :tyrant_rdb_key_store    },
        :store => { :type => :chunked_flat_file_store },
      }

      #
      #
      # +cache+ must behave like a hash (Hash and
      #  Monkeyshines::Store::TyrantRdbKeyStore are both cromulent
      #  choices).
      #
      #
      #
      def initialize _options
        self.options = DEFAULT_OPTIONS.deep_merge(_options)
        self.cache  = Monkeyshines::Store.create(options[:cache])
        self.store  = Monkeyshines::Store.create(options[:store])
        self.misses = 0
      end

      #
      # If key is absent, save the result of calling the block.
      # If key is present, block is never called.
      #
      # Ex:
      #   rt_store.set(url) do
      #     fetcher.get url # will only be called if url isn't in rt_store
      #   end
      #
      def set key, force=nil, &block
        return if (!force) && cache.include?(key)
        cache_val, store_val = block.call()
        return unless cache_val
        cache.set_nr key, cache_val # update cache
        store << store_val          # save value
        self.misses += 1            # track the cache miss
        store_val
      end

      def size() cache.size  end

      def log_line
        [size, "%8d misses"%misses]
      end

      def close()
        cache.close
        store.close
      end
    end
  end
end
