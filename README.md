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

<a name="processor"></a>
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
...

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
it
was
the
worst
of
times.
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

## Combining Processors into Dataflows

Combining processors which each do one thing well together in a chain
is mimicing the tried and true UNIX pipeline.  Wukong lets you define
these pipelines more formally as a dataflow.  Here's the dataflow for
the last example:

```
# in find_t_words.rb
Wukong.dataflow(:find_t_words) do
  tokenizer > regexp(match: /^t/)
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

## Serialization

The process method for a Processor must accept a String argument and
yield a String argument (or something that will `to_s` appropriately).

**Coming Soon:** The ability to define `consumes` and `emits` to
  automatically handle serialization and deserialization.

## Widgets

Wukong has a number of built-in widgets that are useful for
scaffolding your dataflows.
