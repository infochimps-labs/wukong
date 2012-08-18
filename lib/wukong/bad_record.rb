#
# Easily serialize bad records in-band, for later analysis or to discard if
# neglectable.
#
# You can instantiate this as
#  success = do_stuff_to record
#  if ! success
#    return BadRecord.new("do_stuff_to-failed", record)
#  end
#
class BadRecord
  include Gorillib::Model
  field :errors, String,  position: 0
  field :record, Whatever, position: 1

  def initialize errors='', *record_fields
    super errors, record_fields
  end
end
