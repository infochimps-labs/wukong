require File.expand_path('../examples_helper', File.dirname(__FILE__))

Wukong.processor :pig_latinize do

  CONSONANTS = "bcdfghjklmnpqrstvwxz"
  UPPERCASE  = /^[A-Z]/

  # Regular expression to identify the parts of a pig-latin-izable word
  PIG_LATIN_WORD_RE = %r{
    \b                  # word boundary
    ([#{CONSONANTS}]*)  # all initial consonants
    ([\w\']+)           # remaining word characters
  }xi

  def latinize(line)
    line.gsub(PIG_LATIN_WORD_RE) do
      init, rest = [$1, $2]
      init = 'w'       if init.blank?
      rest.capitalize! if init =~ UPPERCASE
      "#{rest}#{init.downcase}ay"
    end
  end

  def process(line)
    emit latinize(line)
  end

end

ExampleUniverse.dataflow(:pig_latin) do
  set_input  :default, file_source(Pathname.path_to(:data, 'text/gift_of_the_magi.txt'))
  set_output :default, file_sink(  Pathname.path_to(:tmp, 'text/pig_latin/gift_of_the_magi.txt'))

  input(:default) > pig_latinize > output(:default)
end
