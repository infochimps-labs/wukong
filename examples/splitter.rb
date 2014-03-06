require 'wukong'

module Verbose

  def verbose?
  end
  
  def setup
    # log.info("Setting up #{label}")
  end

  def finalize
    # log.info("Finalizing #{label}")
  end
end
  
Wukong.processor(:upcaser) do
  include Verbose
  def process(string)
    # log.info("#process #{string}")
    yield string.upcase
  end
end

Wukong.processor(:downcaser) do
  include Verbose
  def process(string)
    # log.info("#process #{string}")
    yield string.downcase
  end
end

Wukong.processor(:tokenizer) do
  include Verbose
  def process string
    # log.info("#process #{string}")
    string.split.each { |token| yield token }
  end
end

Wukong.processor(:stripper) do
  include Verbose
  def process(string)
    # log.info("#process #{string}")
    yield string.gsub(/[^\w\s]/,'')
  end
end

Wukong.processor(:devoweler) do
  include Verbose
  def process(string)
    # log.info("#process #{string}")
    yield string.gsub(/[aeiou]/i,'')
  end
end

# stripper  = Wukong.registry.retrieve(:stripper)
# tokenizer = Wukong.registry.retrieve(:tokenizer)
# upcaser   = Wukong.registry.retrieve(:upcaser)
# downcaser = Wukong.registry.retrieve(:downcaser)
# devoweler = Wukong.registry.retrieve(:devoweler)

# Splitter = Class.new(Wukong::Dataflow)
# builder = Wukong::DataflowBuilder.receive({label: :splitter,
#                                             for_class: Splitter,
#                                             stages: {
#                                               stripper:  stripper,
#                                               tokenizer: tokenizer,
#                                               upcaser:   upcaser,
#                                               downcaser: downcaser,
#                                               devoweler: devoweler,
#                                             },
#                                             links: [
#                                                     Hanuman::LinkFactory.connect(:simple, :stripper, :tokenizer),
#                                                     Hanuman::LinkFactory.connect(:simple, :tokenizer, :upcaser),
#                                                     Hanuman::LinkFactory.connect(:simple, :tokenizer, :downcaser),
#                                                     Hanuman::LinkFactory.connect(:simple, :upcaser, :devoweler),
#                                                    ]})

# builder.extract_links!
# Splitter.set_builder(builder)
# Splitter.register

Wukong.dataflow(:splitter) do
  stripper | tokenizer |
    [
     upcaser | devoweler |
     [
      regexp | count,
      identity
     ],
     downcaser | reject { |word| word == 'hell' }
    ]
end
