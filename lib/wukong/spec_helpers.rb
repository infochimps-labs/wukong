require 'wukong'
require_relative('spec_helpers/unit_tests')
require_relative('spec_helpers/integration_tests')
require_relative('spec_helpers/shared_examples')

module Wukong
  
  # This module lets you use write processor specs at a high level.
  # Require it in your <tt>spec_helper.rb</tt> file:
  #
  #   # in your spec/spec_helper.rb
  #   require 'wukong/spec_helpers'
  #   RSpec.configure do |config|
  #     include Wukong::SpecHelpers
  #   end
  #   
  # Processors in a Wukong spec will have a collection of
  # <tt>given_*</tt> methods you can use to (lazily) feed them records
  # without having to have to build your own driver to run the
  # processors.
  #
  # To each <tt>given_*</tt> method corresponds an <tt>emit_*</tt>
  # matcher which will actually run the processor on the given
  # inputs and compare against expected results.  Here's an example,
  # using a simple `tokenizer` processor.
  #
  #   subject { processor(:tokenizer) }
  #
  #   it "emits each word in a given string" do
  #     given("It was the best of times, it was the worst of times.").should emit(12).records
  #   end
  #
  #   # Give similar input and check against explicit expected
  #   # output.
  #   it "should ignore punctuation and capitalization" do
  #     processor.given("You're crazy!").should emit("youre", "crazy")
  #   end
  #
  #   # Pass the input but transform to JSON first (delimited and
  #   # as_tsv also work).
  #   it "should tokenize the 'text' attribute of a record if given JSON" do
  #     processor.given("text" => "Will be cast to JSON").as_json.should emit("will", "be", "cast", "to", "json")
  #   end
  #
  #   # Initialize the :tokenizer processor with arguments to test
  #   # behavior under different conditions.
  #   it "should output a single record when asked for JSON output" do
  #     processor(:json => true).given("It was the best of times, it was the worst of times.").should emit(1).records
  #   end
  #
  #   # Initialize processor with arguments and express that the
  #   # expected output will be in JSON though given as an object.
  #   it "should output all the tokens for its input record with its JSON output" do
  #     processor(:json => true).given("You're crazy!").should emit("tokens" => ["youre", "crazy"]).as_json
  #   end
  #
  #   # Initialize processor with arguments, and both input and
  #   # output will be serialized/deserialized to/from JSON
  #   # automatically.
  #   it "can read and write pure JSON" do
  #     processor(:json => true).given("text" => "You're crazy!").as_json.should emit("tokens" => ["youre", "crazy"]).as_json
  #   end
  #
  #   # Use a processor outside the scope of the top-level :describe
  #   # block.
  #   it "has a friend which does the same thing" do
  #     processor(:similar_tokenizer, :json => true).given("hi there").should emit(2).records
  #   end
  module SpecHelpers
    include UnitTests
    include IntegrationTests
  end
end

