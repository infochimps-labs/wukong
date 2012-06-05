# "Telegram Problem"
#
# The "Telegram Problem", originally described by Peter Naur:
# * accepts lines of text
# * generates output lines that are shortern than a given length (or contain only one word)
# * without splitting any of the words in the text (if a word is longer than the line width, emit it on its own line).

Wukong.processor :recompose do
  field :break_length, Integer
  attr_accessor :line

  def initialize(*) super; @line = "" ; end

  def process(word)
    if word == "" then flush! ; emit("") ; return ; end
    flush! if "#{line} #{word}".lstrip.length > break_length
    if word.length >= break_length
      emit word
    else
      line << " " << word
    end
  end

  def flush!
    emit line[1..-1] unless line.blank?
    self.line = ""
  end

  def stop
    flush!
  end
end

class TelegramUniverse ; extend Wukong::Universe ; end
TelegramUniverse.dataflow(:telegram) do
  input   :default, file_source(Pathname.path_to(:data, 'text/rectification_of_names.txt'))
  output  :dump,    file_sink(  Pathname.path_to(:tmp,  'output/dataflow/telegram/names.txt'))

  input(:default) >
    map{|line| line.blank? ? [""] : line.strip.split(/\s+/m) } >
    flatten >
    recompose(:break_length => 80) >
    output(:dump)
end
