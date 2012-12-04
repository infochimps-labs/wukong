# Wukong

Wukong is a toolkit for rapid, agile development of data applications
at any scale.

The core concept in Wukong is a **Processor**.  Wukong processors are
simple Ruby classes that do one thing and do it well.  This codebase
implements processors and other core Wukong classes and provides a
tool, `wu-local`, to run and combine processors on the command-line.

Wukong's larger theme is *powerful black boxes, beautiful glue*. The
Wukong ecosystem consists of other tools which run Wukong processors
in various topologies across a variety of different backends.  Code
written in Wukong can be easily ported between environments and
frameworks: local command-line scripts on your laptop instantly turn
into powerful jobs running in Hadoop.

Here is a list of various other projects which you may also want to
peruse when trying to understand the full Wukong experience:

* <a href="http://github.com/infochimps-labs/wukong-hadoop">wukong-hadoop</a>: Run Wukong processors as mappers and reducers within the Hadoop framework.  Model Hadoop jobs locally before you run them.
* <a href="http://github.com/infochimps-labs/wonderdog">wonderdog</a>: Connect Wukong processors running within Hadoop to Elasticsearch as either a source or sink for data.
* <a href="http://github.com/infochimps-labs/wukong-deploy">wukong-deploy</a>: Orchestrate Wukong and other wu-tools together to support an application running on the Infochimps Platform.

For a more holistic perspective also see the Infochimps Platform
Community Edition (**FIXME: link to this**) which combines all the
Wukong tools together into a jetpack which fits comfortably over the
shoulders of developers.

<a name="processors"></a>
## Writing Simple Processors

The fundamental unit of computation in Wukong is the processor.  A
processor is Ruby class which

* subclasses `Wukong::Processor` (use the `Wukong.processor` method as sugar for this)
* defines a `process` method which takes an input record, does something, and calls `yield` on the output

Here's a processor that reverses all each input record:

```ruby
# in string_reverser.rb
Wukong.processor(:string_reverser) do
  def process string
    yield string.reverse
  end
end
```

When you're developing your application, run your processors on the
command line on flat input files using `wu-local`:

```
$ cat novel.txt
It was the best of times, it was the worst of times.
...

$ cat novel.txt | wu-local string_reverser.rb
.semit fo tsrow eht saw ti ,semit fo tseb eht saw tI
```

You can use yield as often (or never) as you need.  Here's a more
complicated example to illustrate:

```ruby
# in processors.rb

Wukong.processor(:tokenizer) do
  def process line
    line.split.each { |token| yield token }
  end
end
  
Wukong.processor(:starts_with) do

  field :letter, String, :default => 'a'
  
  def process word
    yield word if word =~ Regexp.new("^#{letter}", true)
  end
end
```

Let's start by running the `tokenizer`.  We've defined two processors
in the file `processors.rb` and neither one is named `processors` so
we have to tell `wu-local` the name of the processor we want to run
explicitly.

```
$ cat novel.txt | wu-local processors.rb --run=tokenizer
It
was
the
best
of
times,
...
```

You can combine the output of one processor with another right in the
shell.  Let's add the `starts_with` filter and also pass in the
*field* `letter`, defined in that processor:

```
$ cat novel.txt | wu-local processors.rb --run=tokenizer | wu-local processors.rb --run=starts_with --letter=t
the
times
the
times
...
```

Wanting to match on a regular expression is such a common task that
Wukong has a built-in "widget" called `regexp` that you can use
directly:

```
$ cat novel.txt | wu-local processors.rb --run=tokenizer | wu-local regexp --match='^t'
```

There are many more simple <a href="#widgets">widgets</a> like these.

<a name="flows"></a>
## Combining Processors into Dataflows

Combining processors which each do one thing well together in a chain
is mimicing the tried and true UNIX pipeline.  Wukong lets you define
these pipelines more formally as a dataflow.  Here's the dataflow for
the last example:

```
# in find_t_words.rb
Wukong.dataflow(:find_t_words) do
  tokenizer | regexp(match: /^t/)
end
```

The DSL Wukong provides for combining processors is designed to
similar to the processing of developing them on the command line.  You
can run this dataflow directly

```
$ cat novel.txt | wu-local find_t_words.rb
the
times
the
times
...
```

and it works exactly like before.

<a name="serialization></a>
## Serialization

The process method for a Processor must accept a String argument and
yield a String argument (or something that will `to_s` appropriately).

**Coming Soon:** The ability to define `consumes` and `emits` to
  automatically handle serialization and deserialization.

<a name="widgets></a>
## Widgets

Wukong has a number of built-in widgets that are useful for
scaffolding your dataflows.

### Serializers

Serializers are widgets which don't change the semantic meaning of a
record, merely its representation.  Here's a list:

* `to_json`, `from_json` for turning records into JSON or parsing JSON into records
* `to_tsv`, `from_tsv` for turning Array records into TSV or parsing TSV into Array records
* `pretty` for pretty printing JSON inputs

When you're writing processors that are capable of running in
isolation you'll want to ensure that you deserialize and serialize
records on the way in and out, like this

```ruby
Wukong.processor(:on_my_own) do
  def process json
    obj = MultiJson.load(json)
    
    # do something with obj...
    
    yield MultiJson.dump(obj)
  end
end
```

For processors which will only run inside a data flow, you can
optimize by not doing any (de)serialization until except at the very
beginning and at the end

```ruby
Wukong.dataflow(:complicated) do
  from_json | proc_1 | proc_2 | proc_3 ... proc_n | to_json
end
```

in this approach, no serialization will be done between processors.

### General Purpose

There are several general purpose processors which implement common
patterns on input and output data.  These are most useful within the
context of a dataflow definition.

* `null` does what you think it doesn't
* `map` perform some block on each
* `flatten` flatten the input array
* `filter`, `select`, `reject` only let certain records through based on a block
* `regexp`, `not_regexp` only pass records matching (or not matching) a regular expression
* `limit` only let some number of records pass
* `logger` send events to the local log stream
* `extract` extract some part of each input event

Some of these widgets can be used directly, perhaps with some
arguments

```ruby
Wukong.processor(:log_everything) do
  proc_1 | proc_2 | ... | logger
end

Wukong.processor(:log_everything_important) do
  proc_1 | proc_2 | ... | regexp(match: /important/i) | logger
end
```

Other widgets require a block to define their action:

```ruby
Wukong.processor(:log_everything_important) do
  parser | select { |record| record.priority =~ /important/i } | logger
end
```

### Reducers

There are a selection of widgets that do aggregative operations like
counting, sorting, and summing.

* `count` emits a final count of all input records
* `sort` can sort input streams
* `group` will group records by some extracting part and give a count of each group's size
* `moments` will emit more complicated statistics (mean, std. dev.) on the group given some other value to measure

Here's an example of sorting data right on the command line

```
$ head tokens.txt | wu-local sort
abhor
abide
abide
able
able
able
about
...
```

Try adding group:

```
$ head tokens.txt | wu-local sort | wu-local group
{:group=>"abhor", :count=>1}
{:group=>"abide", :count=>2}
{:group=>"able", :count=>3}
{:group=>"about", :count=>3}
{:group=>"above", :count=>1}
...
```

You can also use these within a more complicated dataflow:

```ruby
Wukong.dataflow(:word_count) do
  tokenize | remove_stopwords | sort | group
end
```

## Testing

Wukong comes with several helpers to make writing specs using
[RSpec](http://rspec.info/) easier.

The only method that you need to test in a Processor is the `process`
method.  The rest of the processor's methods and functionality are
provided by Wukong and are already tested.

You may want to test this process method in two ways:

* unit tests of the class itself in various contexts
* integration tests of running the class with the `wu-local` (or other) command-line runner

### Unit Tests

Let's start with a simple processor

```ruby
# in tokenizer.rb
Wukong.processor(:tokenizer) do
  def process text
    text.downcase.gsub(/[^\s\w]/,'').split.each do |token|
      yield token
    end
  end
end
```

You could test this processor directly:

```ruby
# in spec/tokenizer_spec.rb
require 'spec_helper'
describe :tokenizer do
  subject { Wukong::Processor::Tokenizer.new }
  before  { subject.setup                    }
  after   { subject.finalize ; subject.stop  }
  it "correctly counts tokens" do
    expect { |b| subject.process("Hi there, Wukong!", &b) }.to yield_successive_args('hi', 'there', 'wukong')
  end
end
```

but having to handle the yield from the block yourself can lead to
verbose and unreadable tests.  Wukong defines some helpers for this
case.  Require and include them first in your `spec_helper.rb`:

```ruby
# spec/spec_helper.rb
require 'wukong'
require 'wukong/spec_helpers'
RSpec.configure do |config|
  config.include(Wukong::SpecHelpers)
end
```

and then use them in your test

```ruby
# in spec/tokenizer_spec.rb
require 'spec_helper'
describe :tokenizer do
  it_behaves_like 'a processor', :named => :tokenizer
  it "emits the correct number of tokens" do
    processor.given("Hi there.\nMy name is Wukong!").should emit(6).records
  end
  it "eliminates all punctuation" do
    processor.given("Never!").output.first.should_not include(',')
  end
  it "downcases all input text" do
    processor.given("Whatever").output.first.should match(/^w/)
  end
end
```

Let's look at each kind of helper:

* The `a processor` shared example (invoked with RSpec's
  `it_behaves_like` helper) adds some tests that ensure that the
  processor conforms to the API of a Wukong::Processor.

* The `processor` method instantiates a processor very similarly to
  the way `wu-local` instantiates one on the command-line.  It accepts
  a (registered) processor name and options and creates a new
  processor.  If no name is given, the argument of the enclosing
  `describe` or `context` block is used.  The object returned by
  `processor` is the Wukong::Processor you're testing so you can
  directly declare introspect on it or declare expectations about its
  behavior.

* The `given` method (and other helpers like `given_json`,
  `given_tsv`, &c.) is added to the Processor class when
  Wukong::SpecHelpers is required. It's a way of lazily feeding
  records to a processor, without having to go through the `process`
  method directly and having to handle the block or the processor's
  lifecycle as in the prior example.

* The `output` and `emit` matchers will `process` all previously
  `given` records when they are called. This lets you separate
  instantiation, input, expectations, and output. Here's a more
  complicated example:

The same helpers can be used to test dataflows as well as
processors. For complete details, see documentation for the
Wukong::SpecHelpers module.

### Integration Tests

Sometimes unit tests aren't enough and you need to test your
processors or flows as they will be run in production using
`wu-local`.

For these use cases, Wukong provides some integration helpers that
make testing command line processes easier.

```ruby
# spec/integration/tokenizer_spec.rb
context "running the tokenizer with wu-local" do
  subject { command("wu-local tokenizer") < "hi there" }
  it { should exit_with(0)               }
  it { should have_stdout("hi", "there") }
end

context "interpreting its arguments" do
  context "with a valid --match argument" do
    subject { command("wu-local tokenizer --match='^hi'") < "hi there" }
	it      { should     exit_with(0) }
	it      { should     have_stdout("hi")    }
	it      { should_not have_stdout("there") }
  end
  context "with a malformed --match argument" do
    # invalid b/c the regexp is broken...
    subject { command("wu-local tokenizer --match='^[h'") < "hi there" }
	it      { should exit_with(:non_zero)   }
	it      { should have_stderr(/invalid/) }
  end
end
```

Let's go through the helpers:

* The `command` helper creates a wrapper around a command-line that will be launched.  The command's environment and working directory will be taken from the current values of `ENV` and `Dir.pwd`, unless

  * The `in` or `using` arguments are chained with `command` to specify the working directory and environment:

  ```ruby
  command("some-command with --args").in("/my/working/directory").using("THIS" => "ENV_HASH", "WILL_BE" => "MERGED_OVER_EXISTING_ENV")
  ```

  * The scope in which the `command` helper is called defines methods `integration_cwd` and `integration_env`.  This can be done through including a module in your `spec_helper.rb`:

  ```ruby
  # in spec/support/integration_helper.rb
  module IntegrationHelper
    def integration_cwd
	  "/my/working/directory"
	end
	def integration_env
	  { "THIS" => "ENV_HASH", "WILL_BE" => "MERGED_OVER_EXISTING_ENV" }
	end
  end

  # in spec/spec_helper.rb
  require_relative("support/integration_helper")
  RSpec.configure do |config|
    config.include(IntegrationHelper)
  end
  ```  

* The `command` helper can accept input with the `<` method.  Input can be either a String or an Array of strings.  It will be passed to the command over STDIN.

* The `have_stdout` and `have_stderr` matchers let you test the STDOUT or STDERR of the command for particular strings or regular expressions.

* The `exit_with` matcher lets you test the exit code of the command.  You can pass the symbol `:non_zero` to set the expectation of _any_ non-zero exit code.
