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
     class AccumulatingReducer < Streamer
       attr_accessor :last_key
       def initialize options
         super options
         reset!
       end

       #
       # override for multiple-field keys, etc.
       #
       def get_key *vals
         vals.first
       end

       #
       # Accumulate all values for a given key.
       #
       # When the last value for the key is seen, finalize processing and adopt the
       # new key.
       #
       def process *vals
         key = get_key(*vals)
         # if we've seen nothing, adopt key
         self.last_key ||= key
         # if this is a new key,
         if key != self.last_key
           finalize                # process what we've collected so far
           reset!                  # then forget about that key
           self.last_key = key     # and start a new one
         end
         # collect the current line
         accumulate *vals
       end

       #
       # reset! is called after finalizing a batch of key sightings
       #
       # Make sure to call +super+ if you override
       #
       def reset!
         self.last_key = nil
       end

       #
       # Override this to accumulate each value for the given key in turn.
       #
       def accumulate
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
         finalize
       end
     end

   end
end
