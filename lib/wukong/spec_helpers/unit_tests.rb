require_relative('unit_tests/unit_test_driver')
require_relative('unit_tests/unit_test_runner')
require_relative('unit_tests/unit_test_matchers')

module Wukong
  module SpecHelpers

    # This module defines helpers that are useful when running unit
    # tests for processors.
    module UnitTests

      # Create and boot up a runner of the given `klass`.
      #
      # Options to the runner class are given in the `args` Array.
      # The last element of this Array can be a Hash of options to
      # directly pass to the runner (especially useful in unit tests).
      # The rest of the elements are strings that will be parsed as
      # though they were command-line arguments.
      #
      # @example Create a runner that simulates `wu-local` with a set of arguments
      #
      #   runner Wukong::Local::LocalRunner, 'wu-local', '--foo=bar', '--baz=boof', wof: 'bing'
      #
      # A passed block will be eval'd in the context of the newlyl
      # created runner instance.  This can be used to interact with
      # the runner's insides after initialization.
      #
      # @example Create a custom runner and set a property on it
      #
      #   runner(CustomRunner, 'wu-custom', '--foo=bar') do
      #     # eval'd in scope of new runner instance
      #     do_some_special_thing!
      #   end
      #
      # @param [Class] klass
      # @param [String] program_name
      # @param [Array<String>, Hash] args
      def runner klass, program_name, *args, &block
        settings = args.extract_options!
        
        ARGV.replace(args.map(&:to_s))

        klass.new.tap do |the_runner|
          the_runner.program_name = program_name
          the_runner.instance_eval(&block) if block_given?
          the_runner.boot!(settings)
        end
      end

      # Create a runner for unit tests in a variety of convenient
      # ways.
      #
      # Most simply, called without args, will return a UnitTestRunner
      # a the klass named in the containing `describe` or `context`:
      #
      #   context MyApp::Tokenizer do
      #     it "uses whitespace as the default separator between tokens" do
      #       processor.separator.should == /\s+/
      #     end
      #   end
      #
      # if your processor has been registered (you created it with the
      # <tt>Wukong.processor</tt> helper method or otherwise
      # registered it yourself) then you can use its name:
      #
      #   context :tokenizer do
      #     it "uses whitespace as the default separator between tokens" do
      #       processor.separator.should == /\s+/
      #     end
      #   end
      #
      # The `processor` method can also be used inside RSpec's
      # `subject` and `let` methods:
      #
      #   context "with no arguments" do
      #     subject { processor }
      #       it "uses whitespace as the default separator between tokens" do
      #         separator.should == /\s+/
      #       end
      #     end
      #   end
      #
      # and you can easily pass arguments, just like you would on the
      # command line or in a dataflow definition:
      # 
      #   context "with arguments" do
      #     subject { processor(separator: ' ') }
      #       it "uses whitespace as the default separator between tokens" do
      #         separator.should == ' '
      #       end
      #     end
      #   end
      #
      # You can even name the processor directly if you want to:
      #
      #   context "tokenizers" do
      #     let(:default_tokenizer) { processor(:tokenizer)                                          }
      #     let(:complex_tokenizer) { processor(:complex_tokenizer, stemming: true)                  }
      #     let(:french_tokenizer)  { processor(:complex_tokenizer, stemming: true, language: 'fr')  }
      #     ...
      #   end
      def unit_test_runner *args
        settings = args.extract_options!
        name     = (args.first || self.class.description)
        runner   = UnitTestRunner.new(name, settings)
        yield runner.driver.processor if block_given?
        runner.boot!
        runner.driver
      end
      alias_method :processor, :unit_test_runner

      def emit *expected
        UnitTestMatcher.new(*expected)
      end

      def emit_json *expected
        JsonMatcher.new(*expected)
      end

      def emit_delimited delimiter, *expected
        DelimiterMatcher.new(delimiter, *expected)
      end

      def emit_tsv *expected
        TsvMatcher.new(*expected)
      end

      def emit_csv *expected
        CsvMatcher.new(*expected)
      end
    end
    
  end
end
