module Wukong
  class Looper < Wukong::Source

    def each
      loop do
        yield generate
      end
    end

  end

  require 'forgery'
  class ForgeryLooper < Looper
    def generate
      Forgery.text(:sentence, 1)
    end
  end
end
