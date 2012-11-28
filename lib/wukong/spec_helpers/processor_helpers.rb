module Wukong
  module SpecHelpers
    module ProcessorHelpers

      # Creates a new processor in a variety of convenient ways.
      #
      # Most simply, called without args, will return a new instance of
      # a the klass named in the containing +describe+ or +context+:
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
      # The +processor+ method can also be used inside RSpec's
      # +subject+ and +let+ methods:
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
      #     let(:default_tokenizer) { processor(:tokenizer)                          }
      #     let(:complex_tokenizer) { processor(:complex_tokenizer, stemming: true)  }
      #     let(:french_tokenizer)  { processor(:complex_tokenizer, stemming: true)  }
      #     ...
      #   end
      def processor *args, &block
        case
        when args.empty?
          create_processor(self.class.description, {}, &block)
        when args.first.is_a?(Hash)
          create_processor(self.class.description, args.first, &block)
        else
          create_processor(args[0], (args[1] || {}), &block)
        end
      end
      alias_method :flow, :processor

      # Is the given +klass+ a Wukong::Processor?
      #
      # @param [Class] klass
      # @return [true, false]
      def processor? klass
        klass.build.is_a?(Processor)
      end

      # :nodoc:
      def create_processor name_or_klass, options={}, &block
        if name_or_klass.is_a?(Class)
          klass = name_or_klass
        else
          klass = Wukong.registry.retrieve(name_or_klass.to_s.to_sym)
          raise Error.new("Could not find a Wukong::Processor class named '#{name_or_klass}'") if klass.nil?
        end
        raise Error.new("#{klass} is not a subclass of Wukong::Processor") unless processor?(klass)
        settings = Configliere::Param.new
        Wukong.boot!(settings)
        proc = klass.build(settings.merge(options))
        proc.setup
        proc.instance_eval(&block) if block_given?
        proc
      end
    end
  end
end

