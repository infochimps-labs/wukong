module Wu
  module Text
    class WordList
      attr_reader :list
      def initialize(list)
        @list = list.freeze
      end

      # Remove all words that are in this list
      # @param words [Array] list of words to filter
      # @return the given array, modified in-place
      def remove!(words)
        words.delete_if{|word| include?(word) }
      end
      # Remove all words that are in this list
      # @param words [Array] list of words to filter
      # @return a new array, having no words from this list
      def remove(words) ; remove!(words.dup) ; end

      # Retain only words that are in this list, modifying the given array
      # @param words [Array] list of words to filter
      # @return the given array, modified in-place
      def retain!(words)
        words.delete_if{|word| not include?(word) }
      end
      # Retain only words that are in this list, modifying the given arry
      # @param words [Array] list of words to filter
      # @return a new array, with only words from this list
      def retain(words) ; retain!(words.dup) ; end

      # @return [Boolean] true if the given word is in this list
      def include?(word) list.include?(word) ; end

      def index(word)
        list.index(word)
      end

      # possible paths to the BSD 'words' list
      WORD_LIST_PATHS = {
        twl:       File.expand_path('../../../data/text/words/twl_06.tsv', File.dirname(__FILE__)),
        osx_words: '/usr/share/dict/words', # OSX
      }
      def self.word_list_path(sym)
        WORD_LIST_PATHS[sym]
      end

      def self.from_file(filename)
        filename = word_list_path(filename) if filename.is_a?(Symbol)
        list = File.readlines(filename)
          .each(&:strip!)
          .each(&:downcase!)
        new(list)
      end
    end

    class Stopwords < WordList
      def initialize(options={})
        options = options.reverse_merge(min_length: 0, remove_apos: false)
        list = STOPWORDS
        list = list.map{|str|    str.gsub(/\'/, "") }                if options[:remove_apos]
        list = list.reject{|str| str.length < options[:min_length] } if (options[:min_length] > 0)
        super(list.to_set)
      end

      STOPWORDS = %w[
        the
        of
        and
        a
        in
        to
        it
        is
        was
        i
        for
        that
        you
        he
        be
        with
        on
        by
        at
        have
        are
        not
        this
        but
        had
        they
        his
        from
        she
        which
        or
        we
        an
        were
        as
        do
        been
        their
        has
        would
        there
        what
        will
        all
        if
        can
        her
        said
        who
        so
        up
        them
        when
        some
        could
        him
        into
        its
        then
        out
        my
        about
        did
        your
        me
        other
        just
        more
        these
        also
        any
        see
        very
        may
        well
        should
        than
        how
        get
        way
        our
        made
        got
        after
        many
        those
        go
        being
        because
        down
        such
        over
        must
        still
        even
        too
        here
        come
        own
        last
        does
        oh
        no
        where
        us
        same
        might
        yes
        put
        another
        most
        again
        under
        much
        why
        each
        while
        off
        went
        used
        without
        give
        within

        am
        aren't
        between
        both
        can't
        cannot
        couldn't
        didn't
        doesn't
        doing
        don't
        hadn't
        hasn't
        haven't
        having
        he'd
        he'll
        he's
        here's
        hers
        how's
        i'd
        i'll
        i'm
        i've
        isn't
        it'd
        it'll
        it's
        let's
        once
        only
        ought
        ours
        she'd
        she'll
        she's
        shouldn't
        that's
        theirs
        there's
        they'd
        they'll
        they're
        they've
        through
        wasn't
        we'd
        we'll
        we're
        we've
        weren't
        what's
        where's
        who's
        won't
        wouldn't
        you'd
        you'll
        you're
        you've
        yours

      ].to_set.freeze

    end
  end
end
