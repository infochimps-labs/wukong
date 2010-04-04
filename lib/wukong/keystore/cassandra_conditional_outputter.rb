
#
# For a stream process that sees a significant number of duplicated heavyweight
# objects, it may be better to deduplicate them midflight (rather than, say,
# using a reducer to effectively `cat | sort | uniq` the data).
#
# This uses a cassandra key-value store to track unique IDs and prevent output
# of any record already present in the database.  (Why cassandra? Because we use
# it in production.  Might be nice to rewrite this example against redis or
# TokyoTyrant or something less demanding.)
#
# Things you have to do:
#
# * Override the conditional_output_key method to distinguish identical records
# * Define a constant CASSANDRA_KEYSPACE giving the Cassandra keyspace you're working in
# * (Optionally) override conditional_output_key_column
#
# * In your cassandra storage-conf.xml, add a column family to your keyspace:
#
#     <Keyspace Name="CorpusAnalysis">
#         <KeysCachedFraction>0.01</KeysCachedFraction>
#
#         <!-- Added for CassandraConditionalOutputter -->
#         <ColumnFamily CompareWith="UTF8Type" Name="LetterPairMapperKeys" />
#
#         <ReplicaPlacementStrategy>org.apache.cassandra.locator.RackUnawareStrategy</ReplicaPlacementStrategy>
#         <ReplicationFactor>1</ReplicationFactor>
#         <EndPointSnitch>org.apache.cassandra.locator.EndPointSnitch</EndPointSnitch>
#     </Keyspace>
#
#  In this example, the CASSANDRA_KEYSPACE is 'CorpusAnalysis' and the
#  conditional_output_key_column is 'LetterPairMapperKeys'
#
# @example
#    Given
#      tweet  123456789   20100102030405     @frank: I'm having a bacon sandwich
#      tweet      24601   20100104136526     @jerry, I'm having your baby
#      tweet    8675309   20100102030405     I find pastrami to be the most sensual of the salted, cured meats.
#      tweet      24601   20100104136526     @jerry, I'm having your baby
#      tweet       1137   20100119234532     These pretzels are making me thirsty
#      ....
#    will emit:
#      tweet  123456789   20100102030405     @frank: I'm having a bacon sandwich
#      tweet      24601   20100104136526     @jerry, I'm having your baby
#      tweet    8675309   20100102030405     I find pastrami to be the most sensual of the salted, cured meats.
#      tweet      24601   20100104136526     @jerry, I'm having your baby
#      tweet       1137   20100119234532     These pretzels are making me thirsty
#      ....
#
module CassandraConditionalOutputter

  #
  # A unique key for the given record. If an object with
  # that key has been seen, it won't be re-emitted.
  #
  # You will almost certainly want to override this method in your subclass.  Be
  # sure that the key is a string, and is encoded properly (Cassandra likes to
  # strip whitespace from keys, for instance).
  #
  def conditional_output_key record
    record.to_s
  end

  #
  # Checks each record against the key cache
  # Swallows records already there,
  #
  #
  def emit record, &block
    key = conditional_output_key(record)
    unless has_key?(key)
      set_key(key)
      super record
    end
  end

  # Check for presence of key in the cache
  def has_key? key
    not key_cache.get(conditional_output_key_column, key).blank?
  end

  # register key in the key_cache
  def set_key key, data={'1' => '1'}
    key_cache.insert(conditional_output_key_column, key, data)
  end

  # nuke key from the key_cache
  def remove_key key
    key_cache.remove(conditional_output_key_column, key)
  end

  #
  # Key cache implementation in Cassandra
  #

  # The cache
  def key_cache
    @key_cache ||= Cassandra.new(CASSANDRA_KEYSPACE)
  end

  # The column to use for the key cache. By default, the class name plus 'Keys',
  # but feel free to override.
  #
  # @example
  #
  #    class FooMapper < Wukong::Streamer::RecordStreamer
  #      include ConditionalOutputter
  #    end
  #    FooMapper.new.conditional_output_key_column
  #    # => 'FooMapperKeys'
  #
  def conditional_output_key_column
    self.class.to_s+'Keys'
  end
end
