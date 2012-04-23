CONSONANTS = /bcdfghjklmnpqrstvwxz/
UPPERCASE  = /[A-Z]/

# Regular expression to identify the parts of a pig-latin-izable word
PIG_LATIN_WORD_RE = %r{
  \b                  # word boundary
  ([#{CONSONANTS}]*)  # all initial consonants
  ([\w\']+)           # remaining word characters
  }xi                 # allow comments, case-insensitive


def Wukong.latinize(line)
  latinized = line.gsub(PIG_LATIN_WORD_RE) do
    init, rest = [$1, $2]
    init = 'w'       if init.blank?
    rest.capitalize! if init =~ UPPERCASE
    "#{rest}-#{init.downcase}ay"
  end
  return latinized
end

if self.to_s == 'Wukong'
  mapper do |input|
    input | map{|line| Wukong.latinize(line) }
  end
end
