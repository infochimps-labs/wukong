#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'
require 'wukong'
require 'wukong/streamer/rank_and_bin_reducer'

#
# This example uses the classes from http://github.com/mrflip/twitter_friends
# (That's sloppy, and I apologize. I'm building this script for that, but it
# seems broadly useful and I'm not maintaining two copies. Once this script is
# more worky we'll make it standalone.  Anyway you should get the picture.)
#
$: << File.dirname(__FILE__)+'/../../projects/twitter_friends/lib'
require 'twitter_friends'; 
require 'twitter_friends/struct_model' ; include TwitterFriends::StructModel


#
# attrs to bin
#
BINNABLE_ATTRS = { 
  :twitter_user => [
    [:followers_count,  :fo   ], 
    [:friends_count,    :fr   ], 
    [:statuses_count,   :st   ],
    [:favourites_count, :fv   ],
    [:created_at,       :crat ]
    ]
}
RESOURCE_ALIASES = { 
  :twitter_user => :u,
}
#
# KLUDGE This is not DRY at all but  let's get it working first
#
BinTwitterUser = TypedStruct.new(
  [:id, Integer],
  *[:fo, :fr, :st, :fv, :crat].map{|attr| [attr, Integer] }
  )
BINNED_RESOURCE_ALIASES = { 
  :u => BinTwitterUser
}

module RankAndBinAttrs
  class ExplodeResourceMapper < Wukong::Streamer::StructStreamer
    #
    # The data expansion of this mapper is large enough that it makes sense to
    # be a little responsible with what we emit.  We'll use the RESOURCE_ALIASES
    # and BINNABLE_ATTRS hashes, above, to dump a more parsimonious
    # representation. 
    #
    def process thing, &block
      attr_abbrs = BINNABLE_ATTRS[thing.resource_name]
      return unless attr_abbrs
      attr_abbrs.each do |attr, abbr|
        yield [
          RESOURCE_ALIASES[thing.resource_name], 
          abbr, 
          thing.send(attr), 
          thing.id.to_i
        ]
      end
    end
  end

  class BinAttrReducer < Wukong::Streamer::RankAndBinReducer
    attr_accessor :last_rsrc_attr
    #
    # Note that we might get several different resources at the same reducer
    #
    def get_key rsrc, attr, val, *args
      if [rsrc, attr] != self.last_rsrc_attr
        # Note: since each partition has the same cardinality, we don't need to
        # fiddle around with the bin_size, etc -- just reset the order
        # parameters' state.
        reset_order_params!
        self.last_rsrc_attr = [rsrc, attr]
      end
      val
    end
    
    #
    # Note well -- we are rearranging the field order to 
    # 
    #   resource_abbr id  attr_abbr  bin
    #
    # for proper sorting to the re-assembler
    #
    def emit record
      rsrc, attr, val, id, numbering, rank, bin = record
      super [rsrc, id, attr, bin]
    end
  end

  class ReassembleObjectReducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :thing
    def klass_from_abbr rsrc_abbr
      BINNED_RESOURCE_ALIASES[rsrc_abbr.to_sym]
    end
    def get_key rsrc_abbr, id, *args
      [rsrc_abbr, id]
    end
    
    def start! rsrc_abbr, id, *args
      klass = klass_from_abbr(rsrc_abbr)
      self.thing = klass.new id
    end
    
    def accumulate rsrc, id, attr, bin
      thing.send("#{attr}=", bin)
    end
    
    def finalize 
      yield thing
    end
  end

  #
  # Two-phase script
  #
  # FIXME -- We need a runner class to manage this.
  #
  class Script < Wukong::Script
    attr_accessor :phase
    # KLUDGE !!
    def initialize 
      super nil, nil
      case options[:phase].to_i
      when 1
        # Phase 1 -- Steal underpants.  Also, disassemble each object, and find
        # the bin for each binnable attribute's value
        self.phase = 1
        self.mapper_klass, self.reducer_klass = [ExplodeResourceMapper, BinAttrReducer]
      when 2
        # Phase 2 -- ????
        raise "Phase 2 : ????"
      when 3
        # Phase 3 -- profit. In this case, put records back together.
        self.phase = 3
        self.mapper_klass, self.reducer_klass = [nil, ReassembleObjectReducer]
      else
        raise "Please run me with a --phase= option"
      end
    end    
    
    def default_options
      extra_options = 
        case self.phase
        # partition on [rsrc, attr]; sort on [rsrc, attr, val]
        when 1  then { :sort_fields => 3, :partition_fields => 2 }
        # sort on [rsrc, id]
        when 3  then { :sort_fields => 2 }
        else { }
        end
      super.merge extra_options
    end
  end
  
  # execute script
  Script.new.run
end
