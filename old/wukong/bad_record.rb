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
class BadRecord < Struct.new(
    :errors,
    :record
    )
  def initialize errors='', *record_fields
    super errors, record_fields
  end
end
