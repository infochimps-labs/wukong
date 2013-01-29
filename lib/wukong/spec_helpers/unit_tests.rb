require_relative('unit_tests/unit_test_driver')
require_relative('unit_tests/unit_test_runner')
require_relative('unit_tests/unit_test_matchers')

module Wukong
  module SpecHelpers

    module UnitTests

      # Create a Runner class and take it through its lifecycle.
      def runner klass, program_name, *args, &block
        settings = args.extract_options!
        
        ARGV.replace(args.map(&:to_s))

        klass.new.tap do |the_runner|
          the_runner.program_name = program_name
          the_runner.instance_eval(&block) if block_given?
          the_runner.boot!(settings)
        end
      end

      # Creates a new processor in a variety of convenient ways.
      #
      # Most simply, called without args, will return a new instance of
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
