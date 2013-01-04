# A simple processor in its own little file.
class StringReverser < Wukong::Processor
  def process line
    yield line.reverse
  end
  register(:string_reverser)
end
