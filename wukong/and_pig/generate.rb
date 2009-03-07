require 'wukong/and_pig/generate/variable_inflections'

module Wukong
  module AndPig

    mattr_accessor :comments
    self.comments = true
    # send output to stdout or to captured pig instance
    mattr_accessor :emit_dest
    # full pathname to the pig executable
    PIG_EXECUTABLE = '/usr/local/bin/pig'

    def self.finish
      PigVar.pig_in_poke.close if PigVar.pig_in_poke.respond_to?(:close)
    end

    #
    # All the embarrassing magick to pretend ruby symbols are pig relations
    #
    class PigVar

      # Output a command
      def self.emit cmd, semicolon=true
        cmd = cmd + ' ;' if semicolon
        case Wukong::AndPig.emit_dest
        when :captured
          pig_in_poke.puts(cmd)
          pig_in_poke.flush
          puts pig_in_poke.gets
        else
          puts(cmd)
        end
      end

      # generate the code
      def self.emit_setter relation, rval
        emit "%-23s\t= %s" % [relation, rval.cmd]
        rval
      end

      # generate the code
      def self.emit_imperative imperative, *rest
        cmd_part = "%-14s \t" % imperative
        arg_part = rest.map{|s| "%14s" % s.to_s }.join(" \t")
        emit cmd_part+arg_part
        rest.first
      end

      def self.pig_in_poke
        return @pig_in_poke if @pig_in_poke
        case Wukong::AndPig.emit_dest
        when :captured
          @pig_in_poke = IO.popen(PIG_EXECUTABLE, "w+")
          @pig_in_poke.sync = true
          @pig_in_poke
        else @pig_in_poke = $stdout
        end
      end

      #
      # Reset the captured pig instance
      #
      def self.reset_pig_in_poke!
        begin pig_in_poke.close ; rescue nil ; end
        @pig_in_poke = nil
      end

      def set!
        self.class.emit_setter(relation, self)
      end

      #
      # Emit a comment
      # skips if Wukong::AndPig.comments is false
      #
      def self.rem comment
        return unless Wukong::AndPig.comments
        PigVar.emit comment.gsub(/(^|\n)(#([\t ]|$))?/, "\n--  "), false
      end
    end

  end
end


