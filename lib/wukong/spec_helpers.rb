require 'wukong'
require 'wukong/boot'
require_relative('spec_helpers/emit_matcher')
require_relative('spec_helpers/driver')
require_relative('spec_helpers/shared_examples')

module Wukong
  
  # This is a module that you can include in your own RSpec test
  # suite:
  #
  #   # in your spec/spec_helper.rb
  #   require 'wukong/spec_helpers'
  #   RSpec.configure do |config|
  #     include Wukong::SpecHelpers
  #   end
  #
  # This will give you the ability to write simple specs like the
  # following
  #
  #   # in spec/processors/tokenizer_spec.rb
  #   require 'spec_helper'
  #   describe :tokenizer do
  #
  #     # Give explicit input records and check count of expected
  #     # output records to the :tokenizer processor named in the
  #     # top-level :describe block.
  #     it "should tokenize a line of text" do
  #       processor.given("It was the best of times, it was the worst of times.").should emit(12).records
  #     end
  #
  #     # Give similar input and check against explicit expected
  #     # output.
  #     it "should ignore punctuation and capitalization" do
  #       processor.given("You're crazy!").should emit("youre", "crazy")
  #     end
  #
  #     # Pass the input but transform to JSON first (delimited and
  #     # as_tsv also work).
  #     it "should tokenize the 'text' attribute of a record if given JSON" do
  #       processor.given("text" => "Will be cast to JSON").as_json.should emit("will", "be", "cast", "to", "json")
  #     end
  #
  #     # Initialize the :tokenizer processor with arguments to test
  #     # behavior under different conditions.
  #     it "should output a single record when asked for JSON output" do
  #       processor(:json => true).given("It was the best of times, it was the worst of times.").should emit(1).records
  #     end
  #
  #     # Initialize processor with arguments and express that the
  #     # expected output will be in JSON though given as an object.
  #     it "should output all the tokens for its input record with its JSON output" do
  #       processor(:json => true).given("You're crazy!").should emit("tokens" => ["youre", "crazy"]).as_json
  #     end
  #
  #     # Initialize processor with arguments, and both input and
  #     # output will be serialized/deserialized to/from JSON
  #     # automatically.
  #     it "can read and write pure JSON" do
  #       processor(:json => true).given("text" => "You're crazy!").as_json.should emit("tokens" => ["youre", "crazy"]).as_json
  #     end
  #
  #     # Use a processor outside the scope of the top-level :describe
  #     # block.
  #     it "has a friend which does the same thing" do
  #       processor(:similar_tokenizer, :json => true).given("hi there").should emit(2).records
  #     end
  module SpecHelpers

    def create_processor *args
      case
      when args.empty?
        name    = self.class.description
        options = {}
      when args.first.is_a?(Hash)
        name    = self.class.description
        options = args.first
      else
        name    = args.shift
        options = (args.shift || {})
      end
      Wukong.boot!(Local::Configuration)
      proc = Wukong.registry.retrieve(name.to_sym).build(Local::Configuration.merge(options))
    end

    def processor *args
      Driver.new(create_processor(*args))
    end
    alias_method :flow, :processor

  end
end
