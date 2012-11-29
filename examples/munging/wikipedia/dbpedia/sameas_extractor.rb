module Dbpedia

  class SameasExtractor < Wukong::Streamer::LineStreamer
    include MungingUtils

    SAME_AS_RE = %r{\A
         <http://dbpedia\.org/resource/(?<title>[^>]+)>
      \s <http://www\.w3\.org/2002/07/owl\#sameAs>
      \s <http://(?<target>[^>]+)>
      \s \.
    \z}x

    def recordize(line)
      same_as = SAME_AS_RE.match(line)
      if not same_as then warn_record("Unrecognized line type", line) ; return end
      [same_as[:title], same_as[:target]]
    end
  end

end
