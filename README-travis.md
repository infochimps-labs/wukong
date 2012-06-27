# Wukong Vanilla (Stripped Down)

In an effort to clean up implementation of Wukong, several pieces are being refactored (read: ripped out) with eye towards cleanliness of code while avoiding excessive and/or unnecessary functionality.

## What We Like


## Waht We Don't Like

## Example Uses

Wukong.dataflow(:word_count_mapper) do
  word_split = map{ |line| line.split(/\s/) }
  input > word_split > flatten > output
end

Wukong.dataflow(:word_count_reducer) do
  input > counter > output
end

Wukong.dataflow(:word_count) do
  input > word_count_mapper > sort > word_count_reducer > output
end

Universe.run do
  stdin > dataflow(:word_count) > stdout
  dataflow(:word_count).input           # <stdin>
  dataflow(:word_count).input(:default) # <stdin>
end

Wukong.dataflow(:demo) do
  inputs                    # []
  input                     # <stub_source>
  inputs                    # c{ :default=<stub_source> }
  input(:default) == input  # true
  input(:bob)               # just made a new input, labelled `:bob`
  input                     # ??? don't know what this should do ??? -- a) made :default, then :bob ; b) made :bob
end

Wukong.dataflow(:stratify) do
   processor(:splitty) do
     # ... stuff to put stuff on named outputs :low, :med, :hi
   end

   splitty(

   
