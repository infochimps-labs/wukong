 module Wukong
   module Streamer

     #
     # AccumulatingReducer makes it easy to apply one operation across all
     # occurrences of each key
     #
     # On each occurrence of a given key, AccumulatingReducer calls
     # accumulate, and at the final occurrence calls finalize.
     #
     # See ListAccumulatingReducer and KeyCountingReducer for examples
     #
     # Make sure you don't have the bad luck, bad judgement or bad approach to
     # accumulate more data than your box can hold before finalizing.
     #
     class AccumulatingReducer < Wukong::Streamer::Base
       attr_accessor :key
       def initialize options
         super options
         self.key = :__first_pass__
       end

       #
       # override for multiple-field keys, etc.
       #
       # Note that get_key is called by +process+ -- so the arguments have
       # already been +recordize+d. In particular, if you are using
       # StructRecordizer (or StructStreamer), you can write this as
       #
       #   def get_key(thing) thing.id.to_i ; end
       #
       def get_key *record
         record.first
       end

       #
       # Accumulate all records for a given key.
       #
       # When the last record for the key is seen, finalize processing and adopt the
       # new key.
       #
       def process *args, &block
         this_key = get_key(*args)
         if this_key != self.key      # if this is a new key,
           unless self.key == :__first_pass__
             finalize(&block)         # process what we've collected so far
           end
           reset! *args               # then forget about that key
           self.key = this_key        # and start a new one
         end
         # collect the current record
         accumulate *args, &block
       end

       #
       # reset! is called after finalizing a batch of key sightings
       #
       # Make sure to call +super+ if you override
       #
       # Passed the first record of the new key, if that helps you at all.
       #
       def reset! *args
         self.key = nil
       end

       #
       # Override this to accumulate each record for the given key in turn.
       #
       def accumulate *args, &block
         raise "override the accumulate method in your subclass"
       end

       #
       #
       # You must override this method.
       #
       def finalize
         raise "override the finalize method in your subclass"
       end

       #
       # Must make sure to finalize the last-seen accumulation.
       #
       def stream
         super
         finalize(){|record| emit record }
       end
     end

   end
end
