require 'oniguruma' ; include Oniguruma

class Wuclan::Twitter::Hashtag < Token
  RE_HASHTAGS = ORegexp.new( '(?:^|\W)\#([\w\-_\.+:=]+\w)(?:\W|$)', 'i', 'utf8' )
end


class Wuclan::Twitter::Smiley < Token
  #
  # Smilies !!! ^_^
  #
  RE_SMILEYS_EYES  = '\\:8;'
  RE_SMILEYS_NOSE  = '\\-=\\*o'
  RE_SMILEYS_MOUTH = 'DP@Oo\\(\\)\\[\\]\\|\\{\\}\\/\\\\'
  RE_KAWAII_EARS   = '\\*\\|!\\/=\\#o@v;\\:\\._'
  RE_SMILEYS = ORegexp.new( %Q{
        (?:^|\\W)                       # non-smilie character
        (
          (?: [\\(\\[#{RE_KAWAII_EARS}df\\\\]{0,3} \\^[_\\-]\\^ [\\]\\)#{RE_KAWAII_EARS}Ab\\/]{,3} ) # super kawaaaaiiii!
         |(?:
            >?
            [#{RE_SMILEYS_EYES}]       # eyes
            [#{RE_SMILEYS_NOSE}]?      # nose, maybe
            [#{RE_SMILEYS_MOUTH}] )    # mouth
         |(?:
            [#{RE_SMILEYS_MOUTH}]      # mouth
            [#{RE_SMILEYS_NOSE}]?      # nose, maybe
            [#{RE_SMILEYS_EYES}]       # eyes
            <? )
         |(?: =[#{RE_SMILEYS_MOUTH}])  # =) (=
         |(?: [#{RE_SMILEYS_MOUTH}]=)  # =) (=
         |(?: \\^[_\\-]\\^  )          # kawaaaaiiii!
         |(?: \\((?:-_-|o\\.O|T_T|\\*\\^\\^\\*|\\^_~)\\);? ) # more faces
         |(?: <3 )                     # heart
         |(?: \\\\m/ )                 # rawk
         |(?: x-\\( )                  # dead
         |(?:XD|:>|:\\?|:<|:\\/)       # few more that don't fit the template
         |(?: :[,\\']\\( )             # snif  # make emacs non-unhappy: ']))
        )
        (?:\\W|$)
       }, 'x')

end


class Wuclan::Twitter::StockToken < Token
  # One or more $signs followed by letters or :^._
  # or string of $$$ signs on their own
  #
  # @example
  #    $AAPL
  #    $DJI^
  #    key$ha
  #    $$$$
  #    cash$
  #
  RE_STOCK_SYMBOL = '\$+[a-zA-Z\:\^\.\_]+|\$\$+'
  RE_STOCK_TOKEN  = ORegexp.new( %Q{(#{RE_STOCK_SYMBOL})} )
end

class Wuclan::Twitter::TweetUrl < Token
  RE_DOMAIN_HEAD       = '(?:[a-zA-Z0-9\\-]+\\.)+'
  RE_DOMAIN_TLD        = '(?:com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum|[a-zA-Z]{2})'
  # RE_URL_SCHEME      = '[a-zA-Z][a-zA-Z0-9\\-\\+\\.]+'
  RE_URL_SCHEME_STRICT = '[a-zA-Z]{3,6}'
  RE_URL_UNRESERVED    = 'a-zA-Z0-9'       + '\\-\\._~'
  RE_URL_OKCHARS       = RE_URL_UNRESERVED + '\'\\+\\,\\;=' + '/%:@'   # not !$&()* [] \|
  RE_URL_QUERYCHARS    = RE_URL_OKCHARS    + '&='
  RE_URL_HOSTPART      = "#{RE_URL_SCHEME_STRICT}://#{RE_DOMAIN_HEAD}#{RE_DOMAIN_TLD}"
  RE_URL               = ORegexp.new( %Q{(
                #{RE_URL_HOSTPART}                    # Host
     (?:(?: \\/ [#{RE_URL_OKCHARS}]+?          )*?    # path:  / delimited path segments
        (?: \\/ [#{RE_URL_OKCHARS}]*[\\w\\-\\+\\~] )  #        where the last one ends in a non-punctuation.
       |                                              #        ... or no path segment
                                              )/?     #        with an optional trailing slash
        (?: \\? [#{RE_URL_QUERYCHARS}]+  )?           # query: introduced by a ?, with &foo= delimited segments
        (?: \\# [#{RE_URL_OKCHARS}]+     )?           # frag:  introduced by a #
      )}, 'ix' )
end

class Wuclan::Twitter::WordToken < Token
  # The text should be clean of twitter-specific token information
  def self.tokenize text
    return [] if text.blank?
    t = ORegexp.new('[^[:word:]\']+','','utf8').gsub(text, " ");
    t = ORegexp.new('([[:word:]])\'([st])').gsub(t, '\1!\2').gsub(/[\s']+/, " ").gsub(/!/, "'")
    words = t.strip.wukong_encode.split(/\s+/)
    words.reject!{|w| w.blank? || (w.length < 3) }
    words
  end
end
