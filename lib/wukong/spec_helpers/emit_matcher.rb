require 'rspec'

RSpec::Matchers.define :emit do |*expected|

  chain :as_json do
    @as_json = true
  end

  chain :delimited do |delimiter|
    @delimited = true
    @delimiter = delimiter
  end

  chain :as_tsv do
    @delimited = true
    @delimiter = "\t"
  end

  chain :records do
    @count_only = true
  end
  chain :record do
    @count_only = true
  end
  
  match do |driver|
    if driver.run
      @ran      = true
      @actual   = driver.outputs
      @expected = expected
      
      @actual_size   = @actual.size
      @expected_size = (@count_only ? expected.first.to_i : expected.size)
      
      case
      when @actual_size == 0 && @expected_size != 0
        @reason = "Expected #{@expected_size} records but didn't emit any"
      when @actual_size != 0 && @expected_size == 0
        @reason = "Expected no output records but emitted #{@actual_size}"
      when @actual_size != @expected_size
        @reason = "Expected #{@expected_size} records but emitted #{@actual_size}"
      else
        compare_record_for_record(actual) unless @count_only
      end
    else
      @reason = "Could not initialize processor"
    end
    @passed = (@reason ? false : true)
  end

  failure_message_for_should do
    if @ran
      "#{@reason}.  Expected #{expected_description}:\n\n  #{expected_representation}\n\nbut got #{actual_description}:\n\n  #{actual_representation}\n\n"
    else
      @reason
    end
  end
  
  failure_message_for_should_not do
    if @ran
      "#{@reason}.  Expected #{expected_description} to NOT match:\n\n  #{expected_representation}"
    else
      @reason
    end
  end
  
  def compare_record_for_record actual
    expected.each_with_index do |expected_record, index|
      @expected  = expected_record
      @actual    = actual[index]
      begin
        parse!
      rescue => e
        @reason = "Could not properly parse the #{ordinalize(index)} record"
        return
      end
      @did_parse = true
      if @reason.nil? && @parsed != @expected
        @reason   = "Mismatch of the #{ordinalize(index)} record"
        return
      end
    end
  end
  
  # http://stackoverflow.com/questions/1081926/how-do-i-format-a-date-in-ruby-to-include-rd-as-in-3rd
  def ordinalize n
    if (11..13).include?(n % 100)
      "#{n}th"
    else
      case n % 10
      when 1; "#{n}st"
      when 2; "#{n}nd"
      when 3; "#{n}rd"
      else    "#{n}th"
      end
    end
  end

  def parse!
    @parsed = case
    when @as_json   then MultiJson.load(@actual)
    when @delimited then @actual.split(@delimiter)
    else @actual
    end
  end

  def actual_description
    case
    when @did_parse && @as_json   then "(after parsing from JSON) an object"
    when @did_parse && @delimited then "(after splitting on '#{@delimiter}') an object"
    else "a #{@actual.class.to_s}"
    end
  end

  def expected_description
    case
    when @as_json   then "JSON matching an #{@expected.class}"
    when @delimited then "'#{@delimter}'-delimited output"
    else @expected.class.to_s
    end
  end

  def actual_representation
    o = (@parsed || @actual)
    o.is_a?(String) ? o : o.inspect
  end

  def expected_representation
    @expected.is_a?(String) ? @expected : @expected.inspect
  end
  
end
