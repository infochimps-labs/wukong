module Wukong
  module SpecHelpers
    class UnitTestRunner < Wukong::Local::LocalRunner
      
      attr_accessor :processor
      
      def initialize name, settings
        self.processor = name
        params = Configliere::Param.new
        params.use(:commandline)
        params.merge!(settings)
        super(params)
      end
      
      def driver
        @driver ||= UnitTestDriver.new(processor, settings)
      end
      
      def run
      end
    end
  end
end
