
module Wukong
  module Models
    class Edge < TypedStruct.new(
        [:src,              Integer],
        [:dest,             Integer]
        )
    end

    class MultiEdge < TypedStruct.new(
        [:src,              Integer],
        [:dest,             Integer],
        [:a_follows_b,      Integer],
        [:b_follows_a,      Integer],
        [:a_replies_b,      Integer],
        [:b_replies_a,      Integer],
        [:a_atsigns_b,      Integer],
        [:b_atsigns_a,      Integer],
        [:a_retweets_b,     Integer],
        [:b_retweets_a,     Integer],
        [:a_favorites_b,    Integer],
        [:b_favorites_a,    Integer]
        )
    end

  end
end
