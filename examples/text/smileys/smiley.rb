module Wuclan::Twitter

  #
  # Smiley face (emoticon) tokens
  #
  # http://mail.google.com/support/bin/answer.py?hl=en&answer=34056
  # http://en.wikipedia.org/wiki/Emoticons
  #
  # :-)  :)  =]  =)       Smiling, happy
  # :-(  =(  :[  :<       frowning, Sad
  # ;-)  ;)  ;]           Wink
  # :D   =D  XD  BD       Large grin or laugh
  # :P   =P  XP           Tongue out, or after a joke
  # <3   S2  :>           Love
  # :O   =O               Shocked or surprised
  # =I   :/  :-\          Bored, annoyed or awkward; concerned.
  # :S   =S  :?           Confused, embarrassed or uneasy
  #
  # Icon          Meaning                 Icon            Meaning                         Icon    Meaning
  # (^_^)         smile                   (^o^)           laughing out loud               d(^_^)b thumbs up (not ears)
  # (T_T)         sad (crying face)       (-.-)Zzz        sleeping                        (Z.Z)   sleepy person
  # \(^_^)/       cheers, "Hurrah!"       (*^^*)          shyness                         (-_-);  sweating (as in ashamed), or exasperated.
  # (*3*)         "Surprise !."           (?_?)           "Nonsense, I don't know."       (^_~)   wink
  # (o.O)         shocked/disturbed       (<.<)           shifty, suspicious              v(^_^)v peace
  #
  # [\\dv](^_^)[bv/]
  #
  class Smiley < Token
    alias_method :smiley, :text

    #
    # Smileys !!! ^_^
    #
    RE_SMILEYS_EYES  = '\\:8;'
    RE_SMILEYS_NOSE  = '\\-=\\*o'
    RE_SMILEYS_MOUTH = 'DP@Oo\\(\\)\\[\\]\\|\\{\\}\\/\\\\'
    RE_KAWAII_EARS   = '\\*\\|!\\/=\\#o@v;\\:\\._'
    RE_SMILEYS = %r{
        (?:^|\W)                       # non-smilie character
        (
          (?: [\(\[#{RE_KAWAII_EARS}df\\]{0,3} \^[_\-]\^ [\]\)#{RE_KAWAII_EARS}Ab\/]{0,3} ) # super kawaaaaiiii!
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
         |(?: =[#{RE_SMILEYS_MOUTH}])  # =) =/
         |(?: [#{RE_SMILEYS_MOUTH}]=)  # /= (=
         |(?: \^[_\-]\^  )             # kawaaaaiiii!
         |(?: \((?:-_-|o\.O|T_T|\*\^\^\*|\^_~)\);? ) # more faces
         |(?: <3 )                     # heart
         |(?: \\m/ )                   # rawk
         |(?: x-\( )                   # dead
         |(?:XD|:>|:\?|:<|:\/)         # few more that don't fit the template
         |(?: :[,\']\( )               # snif  # make emacs non-unhappy: ']))
        )
        (?:\W|$)
       }xo

    #
    # Return a Hashtag object for each fount in the tweet text
    #
    def self.extract_from_tweet tweet
      super tweet, RE_SMILEYS
    end
  end

  Tweet.class_eval do
    def smileys
      Smiley.extract_from_tweet(self)
    end
  end
end
