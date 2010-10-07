# -*- coding: utf-8 -*-
#
# http://www.jroller.com/obie/tags/unicode
# http://www.unicode.org/faq/casemap_charprop.html
# http://unicode.org/reports/tr10/#Conformance
# http://intertwingly.net/stories/2009/11/30/asciize.rb
# http://blog.stevenlevithan.com/archives/javascript-regex-and-unicode
#
# http://xregexp.com/tests/unicode.html

class String
  #
  # Taken from http://intertwingly.net/stories/2009/11/30/asciize.rb
  #
  def asciize(name)
    if name =~ /[^\x00-\x7F]/
      # digraphs.  May be culturally sensitive
      name.gsub! /\xc3\x9f/, 'ss'
      name.gsub! /\xc3\xa4|a\xcc\x88/, 'ae'
      name.gsub! /\xc3\xa5|a\xcc\x8a/, 'aa'
      name.gsub! /\xc3\xa6/, 'ae'
      name.gsub! /\xc3\xb1|n\xcc\x83/, 'ny'
      name.gsub! /\xc3\xb6|o\xcc\x88/, 'oe'
      name.gsub! /\xc3\xbc|u\xcc\x88/, 'ue'

      # latin 1
      name.gsub! /\xc3[\xa0-\xa5]/, 'a'
      name.gsub! /\xc3\xa7/, 'c'
      name.gsub! /\xc3[\xa8-\xab]/, 'e'
      name.gsub! /\xc3[\xac-\xaf]/, 'i'
      name.gsub! /\xc3[\xb2-\xb6]|\xc3\xb8/, 'o'
      name.gsub! /\xc3[\xb9-\xbc]/, 'u'
      name.gsub! /\xc3[\xbd\xbf]/, 'y'

      # Latin Extended-A
      name.gsub! /\xc4[\x80-\x85]/, 'a'
      name.gsub! /\xc4[\x86-\x8d]/, 'c'
      name.gsub! /\xc4[\x8e-\x91]/, 'd'
      name.gsub! /\xc4[\x92-\x9b]/, 'e'
      name.gsub! /\xc4[\x9c-\xa3]/, 'g'
      name.gsub! /\xc4[\xa4-\xa7]/, 'h'
      name.gsub! /\xc4[\xa8-\xb1]/, 'i'
      name.gsub! /\xc4[\xb2-\xb3]/, 'ij'
      name.gsub! /\xc4[\xb4-\xb5]/, 'j'
      name.gsub! /\xc4[\xb6-\xb8]/, 'k'
      name.gsub! /\xc4[\xb9-\xff]|\xc5[\x80-\x82]/, 'l'
      name.gsub! /\xc5[\x83-\x8b]/, 'n'
      name.gsub! /\xc5[\x8c-\x91]/, 'o'
      name.gsub! /\xc5[\x92-\x93]/, 'oe'
      name.gsub! /\xc5[\x94-\x99]/, 'r'
      name.gsub! /\xc5[\x9a-\xa2]/, 's'
      name.gsub! /\xc5[\xa2-\xa7]/, 't'
      name.gsub! /\xc5[\xa8-\xb3]/, 'u'
      name.gsub! /\xc5[\xb4-\xb5]/, 'w'
      name.gsub! /\xc5[\xb6-\xb8]/, 'y'
      name.gsub! /\xc5[\xb9-\xbe]/, 'z'

      # denormalized diacritics
      name.gsub! /\xcc[\x80-\xff]|\xcd[\x80-\xaf]/, ''
    end

    name.gsub /[^\w]+/, '-'
  end

end

if __FILE__ == $PROGRAM_NAME
  i18n = "I\xc3\xb1t\xc3\xabrn\xc3\xa2ti\xc3\xb4n\xc3\xa0liz\xc3\xa6ti\xc3\xb8n"
  puts "#{i18n} => #{i18n.asciize}"
end

# http://www.jroller.com/obie/tags/unicode
#
# require 'iconv'
# require 'unicode'
# 
# class String
#   
#   def to_ascii
#     # split in muti-byte aware fashion and translate characters over 127
#     # and dropping characters not in the translation hash
#     self.chars.split('').collect { |c| (c[0] <= 127) ? c : translation_hash[c[0]] }.join
#   end
#     
#   def to_url_format
#     url_format = self.to_ascii
#     url_format = url_format.gsub(/[^A-Za-z0-9]/, '') # all non-word
#     url_format.downcase!
#     url_format
#   end
#   
#   protected
#   
#     def translation_hash
#       @@translation_hash ||= setup_translation_hash      
#     end
#     
#     def setup_translation_hash
#       accented_chars   = "ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöøùúûüý"
#       unaccented_chars = "AAAAAACEEEEIIIIDNOOOOOxOUUUUYaaaaaaceeeeiiiinoooooouuuuy"
#   
#       translation_hash = Hash.zip(accented_chars.chars, unaccented_chars.chars)
#       translation_hash["Æ".chars[0]] = 'AE'
#       translation_hash["æ".chars[0]] = 'ae'
#       translation_hash
#     end
#     
# end
