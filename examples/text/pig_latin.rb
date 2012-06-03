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

class PigLatinUniverse ; extend Wukong::Universe ; end
PigLatinUniverse.dataflow(:pig_latin) do
  pig_latinize
end
