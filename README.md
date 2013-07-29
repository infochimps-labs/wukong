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
* <a href="http://github.com/infochimps-labs/wukong-storm">wukong-storm</a>: Run Wukong processors within the Storm framework.  Model flows locally before you run them.
* <a href="http://github.com/infochimps-labs/wukong-load">wukong-load</a>: Load the output data from your local Wukong jobs and flows into a variety of different data stores.
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

Here's a processor that reverses each of its input records:

```ruby
# in string_reverser.rb
Wukong.processor(:string_reverser) do
  def process string
    yield string.reverse
  end
end
```

You can run this processor on the command line using text files as
input using the `wu-local` tool that comes with Wukong:

```
$ cat novel.txt
It was the best of times, it was the worst of times.
...

$ cat novel.txt | wu-local string_reverser.rb
.semit fo tsrow eht saw ti ,semit fo tseb eht saw tI
```

The `wu-local` program consumes one line at at time from STDIN and
calls your processor's `process` method with that line as a Ruby
String object.  Each object you `yield` within your process method
will be printed back out on STDOUT.

### Multiple Processors, Multiple (Or No) Yields

Processors are intended to be combined so they can be stored in the
same file like these two, related processors:

```ruby
# in processors.rb

Wukong.processor(:splitter) do
  def process line
    line.split.each { |token| yield token }
  end
end
  
Wukong.processor(:normalizer) do
  def process token
    stripped = token.downcase.gsub(/\W/,'')
	yield stripped if stripped.size > 0
  end
end
```

Notice how the `splitter` yields multiple tokens for each of its input
tokens and that the `normalizer` may sometimes never yield at all,
depending on its input.  Processors are under no obligations by the
framework to yield or return anything so they can easily act as
filters or even sinks in data flows.

There are two processors in this file and neither shares a name with
the basename of the file ("processors") so `wu-local` can't
automatically choose a processor to run.  We can specify one
explicitly with the `--run` option:

```
$ cat novel.txt | wu-local processors.rb --run=splitter
It
was
the
best
of
times,
...
```

We can combine the two processors together

```
$ cat novel.txt | wu-local processors.rb --run=splitter | wu-local processors.rb --run=normalizer
it
was
the
best
of
times
...
```

but there's an easier way of doing this with <a href="#flows">dataflows</a>.

### Adding Configurable Options

Processors can have options that can be set in Ruby code, from the
command-line, a configuration file, or a variety of other places
thanks to [Configliere](http://github.com/infochimps-labs/configliere).

This processor calculates percentiles from observations assuming a
normal distribution given a particular mean and standard deviation.
It uses two *fields*, the mean or average of a distribution (`mean`)
and its standard deviation (`std_dev`).  From this information, it
will measure the percentile of all input values.

```ruby
# in percentile.rb
Wukong.processor(:percentile) do

  SQRT_1_HALF = Math.sqrt(0.5)

  field :mean,    Float, :default => 0.0
  field :std_dev, Float, :default => 1.0

  def process value
    observation = value.to_f
    z_score     = (mean - observation) / std_dev
    percentile  = 50 * Math.erfc(z_score * SQRT_1_HALF)
    yield [observation, percentile].join("\t")
  end
end
```

These fields have default values but you can overide them on the
command line.  If you scored a 95 on an exam where the mean score was
80 points and the standard deviation of the scores was 10 points, for
example, then you'd be in the 93rd percentile:

```
$ echo 95 | wu-local /tmp/percentile.rb --mean=80 --std_dev=10
95.0	93.3192798731142
```

If the exam were more difficult, with a mean of 75 points and a
standard deviation of 8 points, you'd be in the 99th percentile!

```
$ echo 95 | wu-local /tmp/percentile.rb --mean=75 --std_dev=8
95.0	99.37903346742239
```

### The Lifecycle of a Processor

Processors have a lifecycle that they execute when they are run within
the context of a Wukong runner like `wu-local` or `wu-hadoop`.  Each
lifecycle phase corresponds to a method of the processor that is
called:

* `setup` called *after* the Processor is initialized but *before* the first record is processed.  You cannot yield from this method.
* `process` called once for each input record, may yield once, many, or no times.
* `finalize` called after the the *last* record has been processed but while the processor still has an opportunity to yield records.
* `stop` called to signal to the processor that all work should stop, open connections should be closed, &c.  You cannot yield from this method.

The above examples have already focused on the `process` method.

The `setup` and `stop` methods are often used together to handle
external connections

```ruby
# in geolocator.rb
Wukong.processor(:geolocator) do
  field :host, String, :default => 'localhost'
  attr_accessor :connection
  
  def setup
    self.connection = Database::Connection.new(host)
  end
  def process record
    record.added_value = connection.find("...some query...")
  end
  def stop
    self.connection.close
  end
end
```

The `finalize` method is most useful when writing a "reduce"-type
operation that involves storing or aggregating information till some
criterion is met.  It will always be called after the last record has
been given (to `process`) but you can call it whenever you want to
within your own code.

Here's an example of using the `finalize` method to implement a simple
counter that counts all the input records:

```ruby
# in counter.rb
Wukong.processor(:counter) do
  attr_accessor :count
  def setup
    self.count = 0
  end
  def process thing
    self.count += 1
  end
  def finalize
    yield count
  end
end
```

It hinges on the fact that the last input record will be passed to
`process` *first* and only then will `finalize` be called.  This
allows the last input record to be counted/processed/aggregated and
then the entire aggregate to be dealt with in finalize.

Because of this emphasis on building and processing aggregates, the
`finalize` method is often useful within processors meant to run as
reducers in a Hadoop environment.

Note:: Finalize is not guaranteed to be called by in every possible
environment as it depends on the chosen runner.  In a local or Hadoop
environment, the notion of "last record" makes sense and so the
corresponding runners will call `finalize`.  In an environment like
Storm, where the concept of last record is not (supposed to be)
meaningful, the corresponding runner doesn't ever call it.

### Serialization

`wu-local` (and many similar tools) deal with inputs and outputs as
strings.

Processors want to process objects as close to their domain as is
possible.  A processor which decorates address book entries with
Twitter handles doesn't want to think of its inputs as Strings but
Hashes or, better yet, Persons.

Wukong makes it easy to wrap a processor with other processors
dedicated to handling the common tasks of parsing records into or out
of formats like JSON and turning them into Ruby model instances.

#### De-serializing data formats like JSON or TSV

Wukong can parse and emit common data formats like JSON and delimited
formats like TSV or CSV so that you don't pollute or tie down your own
processors with protocol logic.

Here's an example of a processor that wants to deal with Hashes as
input.

```ruby
# in extractor.rb
Wukong.processor(:extractor) do
  def process hsh
    yield hsh["first_name"]
  end
end
```

Given JSON data,

```
$ cat input.json
{"first_name": "John", "last_name":, "Smith"}
{"first_name": "Sally", "last_name":, "Johnson"}
...
```

you can feed it directly to a processor

```
$ cat input.json | wu-local --from=json extractor.rb
John
Sally
...
```

Other processors really like Arrays:

```ruby
# in summer.rb
Wukong.processor(:summer) do
  def process values
    yield values.map(&:to_f).inject(&:+)
  end
end
```

so you can feed them TSV data
```
$ cat data.tsv
1	2	3
4	5	6
7	8	9
...
$ cat data.tsv | wu-local --from=tsv summer.rb
6
15
24
...
```

but you can just as easily use the same code with CSV data

```
$ cat data.tsv | wu-local --from=csv summer.rb
```

or a more general delimited format.

```
$ cat data.tsv | wu-local --from=delimited --delimiter='--' summer.rb
```

#### Recordizing data structures into domain models

Here's a contact validator that relies on a Person model to decide
whether a contact entry should be yielded:

```ruby
# in contact_validator.rb
require 'person'

Wukong.processor(:contact_validator) do
  def process person
    yield person if person.valid?
  end
end
```

Relying on the (elsewhere-defined) Person model to define `valid?`
means the processor can stay skinny and readable.  Wukong can, in
combination with the deserializing features above, turn input text
into instances of Person:

```
$ cat input.json | wu-local --consumes=Person --from=json contact_validator.rb
#<Person:0x000000020e6120>
#<Person:0x000000020e6120>
#<Person:0x000000020e6120>
```

`wu-local` can also serialize records from the `contact_validator`
processor:

```
$ cat input.json | wu-local --consumes=Person --from=json contact_validator.rb --to=json
{"first_name": "John", "last_name":, "Smith", "valid": "true"}
{"first_name": "Sally", "last_name":, "Johnson", "valid": "true"}
...
```

Serialization formats work just like deserialization formats, with
JSON as well as delimited formats available.

Parsing records into model instances and serializing them out again
puts constraints on the model class providing these instances.  Here's
what the `Person` class needs to look like:


```ruby
# in person.rb
class Person

  # Create a new Person from the given attributes.  Supports usage of
  # the `--consumes` flag on the command-line
  # 
  # @param [Hash] attrs
  # @return [Person]
  def self.receive attrs
    new(attrs)
  end
  
  # Turn this Person into a basic data structure.  Supports the usage
  # of the `--to` flag on the command-line.
  # 
  # @return [Hash]
  def to_wire
    to_hash
  end
end
```

To support the `--consumes=Person` syntax, the `receive` class method
must take a Hash produced from the operation of the `--from` argument
and return a `Person` instance.

To support the `--to=json` syntax, the `Person` class must implement
the `to_wire` instance method.

### Logging and Notifications

Wukong comes with a logger that all processors have access to via
their `log` attribute.  This logger has the following priorities:

* debug (can be set as a log level)
* info (can be set as a log level)
* warn (can be set as a log level)
* error
* fatal

and here's a processor which uses them all

```ruby
# in logs.rb
Wukong.processor(:logs) do
  def process line
    log.debug line
    log.info  line
    log.warn  line
    log.error line
    log.fatal line
  end
end
```

The default log level is DEBUG.  

```
$ echo something | wu-local logs.rb
DEBUG 2013-01-11 23:40:56 [Logs                ] -- something
INFO 2013-01-11 23:40:56 [Logs                ] -- something
WARN 2013-01-11 23:40:56 [Logs                ] -- something
ERROR 2013-01-11 23:40:56 [Logs                ] -- something
FATAL 2013-01-11 23:40:56 [Logs                ] -- something
```

though you can set it to something else globally

```
$ echo something | wu-local logs.rb --log.level=warn
WARN 2013-01-11 23:40:56 [Logs                ] -- something
ERROR 2013-01-11 23:40:56 [Logs                ] -- something
FATAL 2013-01-11 23:40:56 [Logs                ] -- something
```

or on a per-class basis.

### Creating Documentation

`wu-local` includes a help message:

```
$ wu-local --help
usage: wu-local [ --param=val | --param | -p val | -p ] PROCESSOR|FLOW

wu-local is a tool for running Wukong processors and flows locally on
the command-line.  Use wu-local by passing it a processor and feeding
...


Params:
   -r, --run=String             Name of the processor or dataflow to use. Defaults to basename of the given path.
```

You can generate custom help messages for your own processors.  Here's
the percentile processor from before but made more usable with good
documentation:

```ruby
# in percentile.rb
Wukong.processor(:percentile) do

  description <<-EOF.gsub(/^ {2}/,'')
  This processor calculates percentiles from input scores based on a
  given mean score and a given standard deviation for the scores.

  The mean and standard deviation are given at run time and processed
  scores will be compared against the given mean and standard
  deviation.

  The input is expected to consist of float values, one per line.

  Example:

    $ cat input.dat
    88
    89
    77
    ...

    $ cat input.dat | wu-local percentile.rb --mean=85 --std_dev=7
    88.0	66.58824291023753
    89.0	71.61454169013237
    77.0	12.654895447355777
  EOF
	
  SQRT_1_HALF = Math.sqrt(0.5)

  field :mean,    Float, :default => 0.0, :doc => "The mean of the assumed distribution"
  field :std_dev, Float, :default => 1.0, :doc => "The standard deviation of the assumed distribution"

  def process value
    observation = value.to_f
    z_score     = (mean - observation) / std_dev
    percentile  = 50 * Math.erfc(z_score * SQRT_1_HALF)
    yield [observation, percentile].join("\t")
  end
end
```

If you call `wu-local` with the file to this processor as an argument
in addition to the original `--help` argument, you'll get custom
documentation.

```
$ wu-local percentile.rb --help
usage: wu-local [ --param=val | --param | -p val | -p ] PROCESSOR|FLOW

This processor calculates percentiles from input scores based on a
given mean score and a given standard deviation for the scores.
...


Params:
       --mean=Float             The mean of the assumed distribution [Default: 0.0]
   -r, --run=String             Name of the processor or dataflow to use. Defaults to basename of the given path.
       --std_dev=Float          The standard deviation of the assumed distribution [Default: 1.0]

```

<a name="flows"></a>
## Combining Processors into Dataflows

Wukong provides a DSL for combining processors together into
dataflows.  This DSL is designed to make it easy to replicate the
tried and true UNIX philosophy of building simple tools which do one
thing well and then combining them together to create more complicated
flows.

For example, having written the `tokenizer` processor, we can use it
in a dataflow along with the built-in `regexp` processor to replicate
what we did in the last example:

```ruby
# in find_t_words.rb
require_relative('processors')
Wukong.dataflow(:find_t_words) do
  tokenizer | regexp(match: /^t/)
end
```

The `|` operator connects the output of one processor (what it
`yield`s) with the input of another (its `process` method).  In this
example, every record emitted by `tokenizer` will be subsequently
processed by `regexp`.

You can run this dataflow directly (mimicing what we did above with
single processors chained together on the command-line):

```
$ cat novel.txt | wu-local find_t_words.rb
the
times
the
times
...
```

### More complicated dataflow topologies

The Wukong dataflow DSL allows for more complicated topologies than
just chaining processors together in a linear pipeline.

The `|` operator, used in the above examples to connect two processors
together into a chain, can also be used to connect a single processor
to *multiple* processors, creating a branch-point in the dataflow.
Each branch of the flow will receive the same records.

This can be used to perform multiple actions with the same record, as
in the following example:

```ruby
# in book_reviews.rb
Wukong.dataflow(:complicated) do
  from_json | recordize(model: BookReview) | 
  [
    map(&:author) | do_author_stuff | ... | to_json,
	map(&:book)   | do_book_stuff   | ... | to_json,
  ]
end
```

Each `BookReview` record yielded by the `recordize` processor will be
passed to both subsequent branches of the flow, with each branch doing
a different kind of processing.  Output records from both branches
(which are here turned `to_json` first) will be interspersed in the
final output when run.

A processor like `select`, which filters its inputs, can be used to
split a flow into records of two types:

```ruby
# in complicated.rb
Wukong.dataflow(:complicated) do
  from_json | parser | 
  [
    select(&:valid?)   | further_processing | ... | to_json,
	select(&:invalid?) | track_errors | null
  ]
end
```

Here, only records which respond true to the method `valid?` will pass
through the first flow (applying `further_processing` and so on) while
only records which respond true to `invalid?` will pass through the
second flow (with `track_errors`).  The `null` processor at the end of
this second branch ensures that only records from the first branch
will be emitted in the final output.

<a name="serialization></a>
## Serialization

The process method for a Processor must accept a String argument and
yield a String argument (or something that will `to_s` appropriately).

**Coming Soon:** The ability to define `consumes` and `emits` to
  automatically handle serialization and deserialization.

<a name="widgets></a>
## Widgets

Wukong has a number of built-in widgets that are useful for
scaffolding your dataflows or using as starting off points for your
own processors.

For any of these widgets you can get customized help, say

```
$ wu-local group --help
```

### Serializers

Serializers are widgets which don't change the semantic meaning of a
record, merely its representation.  Here's a list:

* `to_json`, `from_json` for turning records into JSON or parsing JSON into records
* `to_tsv`, `from_tsv` for turning Array records into TSV or parsing TSV into Array records
* `pretty` for pretty printing JSON inputs

When you're writing processors that are capable of running in
isolation you'll want to ensure that you deserialize and serialize
records on the way in and out, using the serialization/deserialization
options `--to` and `--from` on the command-line, as <a
href="#serialization">defined above</a>.

For processors which will only run inside a data flow, you can
optimize by not doing any (de)serialization until except at the very
beginning and at the end

```ruby
Wukong.dataflow(:complicated) do
  from_json | proc_1 | proc_2 | proc_3 ... proc_n | to_json
end
```

in this approach, no serialization will be done between processors,
only at the beginning and end.

(This is actually the implementation behind the serialization options
themselves -- they dynamically prepend/append the appropriate
deserializers/serializers.)

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
    processor(:tokenizer).given("Never!").should emit('Never')
  end
  it "will not emit tokens in a stop list" do
    processor(:tokenizer, :stop_list => ['apples', 'bananas']).given("I like apples and bananas").should emit('I', 'like', 'and')
  end
end
```

Let's look at each kind of helper:

* The `a processor` shared example (invoked with RSpec's
  `it_behaves_like` helper) adds some tests that ensure that the
  processor conforms to the API of a Wukong::Processor.

* The `processor` method is actually an alias for the more aptly named
  (but less convenient) `unit_test_runner`.  This method accepts a
  processor name and options (just like `wu-local` and other
  command-line tools) and returns a Wukong::UnitTestRunner instance.
  This runner handles the


  a (registered) processor name and options and creates a new
  processor.  If no name is given, the argument of the enclosing
  `describe` or `context` block is used.  The object returned by
  `processor` is the Wukong::Processor you're testing so you can
  directly declare introspect on it or declare expectations about its
  behavior.

* The `given` method (and other helpers like `given_json`,
  `given_tsv`, &c.) is a method on the runner. It's a way of lazily
  feeding records to a processor, without having to go through the
  `process` method directly and having to handle the block or the
  processor's lifecycle as in the prior example.

* The `output` and `emit` matchers will `process` all previously
  `given` records when they are called. This lets you separate
  instantiation, input, expectations, and output. Here's a more
  complicated example.

The same helpers can be used to test dataflows as well as
processors.

#### 

#### Functions vs. Objects

The above test helpers are designed to aid in testing processors
functionally because:

* they accept the 

### Integration Tests

If you are implementing a new Wukong command (akin to `wu-local`) then
you may also want to run integration tests.  Wukong comes with helpers
for these, too.

You should almost always be able to test your processors without
integration tests.  Your unit tests and the Wukong framework itself
should ensure that your processors work correctly no matter what
environment they are deployed in.

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
    subject { command("wu-local tokenizer --match='^(h'") < "hi there" }
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

## Plugins

Wukong has a built-in plugin framework to make it easy to adapt Wukong
processors to new backends or add other functionality.  The
`Wukong::Local` module and the `wu-local` program it supports is
itself a Wukong plugin.

The following shows how you might build a simplified version of
`Wukong::Local` as a new plugin.  We'll call this plugin `Cat` as it
will implement a program `wu-cat` that is similar in function to
`wu-local` (just simplified).

The first thing to do is include the `Wukong::Plugin` module in your
code:


```Ruby
# in lib/cat.rb
#
# This Wukong plugin works like wu-local but replicates some silly
# features of cat like numbered lines.
module Cat

  # This registers Cat as a Wukong plugin.
  include Wukong::Plugin

  # Defines any settings specific to Cat.  Cat doesn't need to, but
  # you can define global settings here if you want.  You can also
  # check the `program` name to decide whether to apply your settings.
  # This helps you not pollute other commands with your stuff.
  def self.configure settings, program
	case program
	when 'wu-cat'
	  settings.define(:input,  :description => "The input file to use")
	  settings.define(:number, :description => "Prepend each input record with a consecutive number", :type => :boolean)
	else
	  # configure other programs if you need to
	end
  end

  # Lets Cat boot up with settings that have already been resolved
  # from the command-line or other sources like config files or remote
  # servers added by other plugins.
  #
  # The `root` directory in which the program is executing is also
  # provided.
  def self.boot settings, root
    puts "Cat booting up using resolved settings within directory #{root}"
  end
end
```

If your plugin doesn't interact directly with the command-line
(through a wu-tool like `wu-local` or `wu-hadoop`) and doesn't
directly interface with passing records to processors then you can
just require the rest of your plugin's code at this point and be done.

### Write a Runner to interact with the command-line

If you need to implement a new command line tool then you should write
a Runner.  A Runner is used to implement Wukong programs like
`wu-local` or `wu-hadoop`. Here's what the actual program file would
look like for our example plugin's `wu-cat` program.

```ruby
#!/usr/bin/env ruby
# in bin/wu-cat
require 'cat'
Cat::Runner.run
```

The Cat::Runner class is implemented separately.

```ruby
# in lib/cat/runner.rb
require_relative('driver')
module Cat

  # Implements the `wu-cat` command.
  class Runner < Wukong::Runner

    usage "PROCESSOR|FLOW"
	
	description <<-EOF
	
	wu-cat lets you run a Wukong processor or dataflow on the
	command-line.  Try it like this.

    $ wu-cat --input=data.txt
	hello
	my
	friend

    Connect the output to a processor in upcaser.rb
	
    $ wu-cat --input=data.txt upcaser.rb
	HELLO
	MY
	FRIEND

    You can also include add line numbers to the output.

    $ wu-cat --number --input=data.txt upcaser.rb
	1	HELLO
	2	MY
	3	FRIEND
    EOF

    # The name of the processor we're going to run.  The #args method
    # is provided by the Runner class.
	def processor_name
	  args.first
	end

    # Validate that we were given the name of a registered processor
	# to run.  Be careful to return true here or validation will fail.
    def validate
      raise Wukong::Error.new("Must provide a processor as the first argument") unless processor_name
	  true
	end

    # Delgates to a driver class to run the processor.
    def run
	  Driver.new(processor_name, settings).start
	end
	
  end
end
```

### Write a Driver to interact with processors

The `Cat::Runner#run` method delegates to the `Cat::Driver` class to
handle instantiating and interacting with processors.

```ruby
# in lib/cat/driver.rb
module Cat

  # A class for driving a processor from `wu-cat`.
  class Driver

    # Lets us count the records.
    attr_accessor :number

    # Gives methods to construct and interact with dataflows.
    include Wukong::DriverMethods

    # Create a new Driver for a dataflow with the given `label` using
    # the given `settings`.
    #
    # @param [String] label the name of the dataflow
    # @param [Configliere::Param] settings the settings to use when creating the dataflow
    def initialize label, settings
      self.settings = settings
      self.dataflow = construct_dataflow(label, settings)
      self.number   = 1
    end

    # The file handle of the input file.
    #
    # @return [File]
    def input_file
      @input_file ||= File.new(settings[:input])
    end

    # Starts feeding records to the processor
    def start
      while line = input_file.readline rescue nil
        driver.send_through_dataflow(line)
      end
    end

    # Process each record that comes back from the dataflow.
	#
	# @param [Object] record the yielded record
    def process record
      if settings[:number]
        puts [number, record].map(&:to_s).join("\t")
      else
        puts record.to_s
      end
	  self.number += 1
    end

  end
end
```
