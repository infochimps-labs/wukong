require 'wukong'


module Wukong
  module SpecHelper

    def processing(input_record, options = {})
      [].tap do |output_records| 
        processor(options).process(input_record) do  |output_record|
          output_records << output_record 
        end
      end
    end

    def processor options
      Wukong.registry.retrieve(self.class.top_level_description.to_sym).build(options)
    end

  end
end

Wukong.processor(:foo_processor) do

  field :regex, String, :default => "\\s"

  def process(rec) rec.split(Regexp.new(regex)).each{ |token| yield token } ; end
  
end

RSpec::Matchers.define :emit do |*expected|

  match do |actual|
    actual == expected
  end
  
end

describe :foo_processor do
  include Wukong::SpecHelper

  it 'splits strings on whitespace by default' do
    processing('foo bar baz').should emit('foo', 'bar', 'baz')
  end

  it 'splits strings on commas' do
    processing('foo,bar,baz', regex: ",").should emit('foo', 'bar', 'baz')
  end

end

