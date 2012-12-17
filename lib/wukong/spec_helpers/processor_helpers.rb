module Wukong
  module SpecHelpers
    module ProcessorHelpers

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
      def flow *args, &block
        options  = args.extract_options!
        name     = args.first || self.class.description
        create_dataflow(name, options, &block)
      end
      alias_method :processor, :flow

      # :nodoc:
      def create_dataflow name, options={}, &block
        settings = Configliere::Param.new
        settings.merge!(options)
        dataflow = SpecDriver.new(name, settings).dataflow
        dataflow.instance_eval(&block) if block_given?
        dataflow
      end
    end
  end
end
