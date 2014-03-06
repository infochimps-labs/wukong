module Wukong
  class Processor

    # A widget that yields whatever you instantiate it with.
    #
    # This is most useful when you have a small but predictable input
    # that you don't want or can't pass via usual input channels like
    # STDIN.
    #
    # @example Works just like you think on the command line
    #
    #   $ echo something else | wu-local echo --input=hello
    #   hello
    #
    # @example Pass some fixed input to your downstream code.
    #
    #   # my_flow.rb
    #   Wukong.dataflow(:my_flow) do
    #     echo(input: {key: 'value'}) | my_proc | ...
    #   end
    #
    # This differs from from the `:identity` processor because it
    # doesn't pass on what it receives but what you instantiate it
    # with.
    #
    # @see Identity
    class Echo < Processor

      description <<EOF
A widget that yields whatever you instantiate it with.

This is most useful when you have a small but predictable input
that you don't want or can't pass via usual input channels like
STDIN.

Works just like you think on the command line (the process won't terminate)

  $ echo something else | wu-local echo --input=hello
  hello
EOF

      field :input, Whatever, :default => nil, :doc => "The record to echo"

      # Yields the `input` no matter what you pass it.
      #
      # @param [Object] _ the new input record which is ignored
      # @yield [input]
      # @yieldparam [Object] input the original input
      def process _
        yield input
      end
      register
    end
  end
end
