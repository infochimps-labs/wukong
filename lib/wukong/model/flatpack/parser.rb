module Flat
  class Parser
    attr_accessor :re
    attr_accessor :lang

    def initialize(lang)
      @lang = lang
      @re = re_from_language @lang
    end

    # returns true if the supplied string is in the parser's language
    def string_in_lang? str
      return (not (str =~ @re).nil?)
    end

    # Creates a regular expression from the 
    # supplied language
    def re_from_language lang
      regex = "^"
      lang.each do |token|
        regex += "(#{token.re})"
      end
      regex += "$"
      return Regexp.new(regex)
    end

    def parse(str,trim=false)
      return nil unless string_in_lang? str
      result = []
      str.match(@re)[1..-1].each_with_index do |val,index|
        token = lang[index].translate(val)
        if trim and token.is_a?(String)
          token.strip!
        end
        result << token
      end
      return result - [:ignore]
    end

    def file_to_tsv(in_filename,out_filename,trim=true)
      infile =  File.open(in_filename,'r')
      outfile = File.open(out_filename,'a')
      infile.each_line do |line|
        outfile.write(line_to_tsv(line,trim))
      end
    end

    def line_to_tsv(line,trim=true)
      fields = parse(line,trim)
      return fields.join("\t") + "\n"
    end
  end
end
