# Wukong [![Build Status](https://secure.travis-ci.org/infochimps-labs/wukong.png)](http://travis-ci.org/infochimps-labs/wukong)

Wukong is a toolkit for rapid, agile development of dataflows at any scale.

(note: the syntax below is mostly false)


<a name="design"></a>
## Design Overview

The fundamental principle of Wukong/Hanuman is *powerful black boxes, beautiful glue*. In general, they don't do the thing -- they coordinate the boxes that do the thing, to let you implement rapidly, nimbly and readably. Hanuman elegantly describes high-level data flows; Wukong is a pragmatic collection of dataflow primitives. They both emphasize scalability, readability and rapid development over performance or universality.

Wukong/Hanuman are chiefly concerned with these specific types of graphs:

* **dataflow**      -- chains of simple modules to handle continuous data processing -- coordinates Flume, Unix pipes, ZeroMQ, Esper, Storm.
* **workflows**     -- episodic jobs sequences, joined by dependency links -- comparable to Rake, Azkaban or Oozie.
* **map/reduce**    -- Hadoop's standard *disordered/partitioned stream > partition, sort & group > process groups* workflow. Comparable to MRJob and Dumbo.
* **queue workers** -- pub/sub asynchronously triggered jobs -- comparable Resque, RabbitMQ/AMQP, Amazon Simple Worker, Heroku workers.

In addition, wukong stages may be deployed into **http middlware**: lightweight distributed API handlers -- comparable to Rack, Goliath or Twisted.

When you're describing a Wukong/Hanuman flow, you're writing pure expressive ruby, not some hokey interpreted language or clumsy XML format. Thanks to JRuby, it can speak directly to Java-based components like Hadoop, Flume, Storm or Spark.

## What's where

* Configliere -- Manage settings
  - Layer - Project settings through a late-resolved stack of config objects.
* Gorillib
  - Type, RecordType
  - TypeConversion
  - Model
  - PathHelpers
* Wukong
  - fs - Abstracts file hdfs s3n s3hdfs scp
  - streamer - Black-box data transform
  - job - Workflow definition
  - flow - Dataflow definition
  - widgets - Common data transforms
  - RubyHadoop - Hadoop jobs using streamers
  - RubyFlume - Flume decorators using streamers
* Hanuman -- Elegant small graph assembly
* Swineherd -- Common interface on ugly tools
  - Turn readable hash into safe commandline (param conv, escaping)
  - Execute command, capture stdin/stderr
  - Summarize execution with a broham-able hash
  - Common modules: Input/output, Java, gnu, configliere
  - Template
  - Hadoop, pig, flume
  - ?? Cp, mv, rm, zip, tar, bz2, gz, ssh, scp
  - ?? Remotely execute command

<a name="design-rules"></a>
### Story

[Narrative Method Structure](http://avdi.org/talks/confident-code-rubymidwest-2011/confident-code.html)

* Gather input
* Perform work
* Deliver results
* Handle failure


<a name="design-rules"></a>
### Design Rules

* **whiteboard rule**: the user-facing conceptual model should match the picture you would draw on the whiteboard in an engineering discussion. The fundamental goal is to abstract the necessary messiness surrounding the industrial-strength components it orchestrates while still providing their essential power.
* **common cases are simple, complex cases are always possible**: The code should be as simple as the story it tells. For the things you do all the time, you only need to describe how this data flow is different from all other data flows. However, at no point in the project lifecycle should Wukong/Hanuman hit a brick wall or peat bog requiring its total replacement. A complex production system may, for example, require that you replace a critical path with custom Java code -- but that's a small set of substitutions in an otherwise stable, scalable graph. In the world of web programming, Ruby on Rails passes this test; Sinatra and Drupal do not.
* **petabyte rule**: Wukong/Hanuman coordinate industrial-strength components that wort at terabyte- and petabyte-scale. Conceptual simplicity makes it an excellent tool even for small jobs, but scalability is key. All components must assume an asynchronous, unreliable and distributed system.
* **laptop rule**:
* **no dark magick**: the core libraries provide *elegant, predictable magic or no magic at all*. We use metaprogramming heavily, but always predictably, and only in service of making common cases simple. 
  - Soupy multi-option `case` statements are a smell.
  - Complex tasks will require code that is more explicit, but readable and organically connected to the typical usage. For example, many data flows will require a custom `Wukong::Streamer` class; but that class is no more complex than the built-in streamer models and receives all the same sugar methods they do.
* **get shit done**: sometimes ugly tasks require ugly solutions. Shelling out to the hadoop process monitor and parsing its output is acceptable if it is robust and obviates the need for a native protocol handler.
* **be clever early, boring late**: magic in service of having a terse language for assembling a graph is great. However, the assembled graph should be stomic and largely free of any conditional logic or dependencies.
  - for example, the data flow `split` statement allows you to set a condition on each branch. The assembled graph, however, is typically a `fanout` stage followed by `filter` stages.
  - the graph language has some helpers to refer to graph stages. The compiled graph uses explicit mostly-readable but unambiguous static handles.
  - some stages offer light polymorphism -- for example, `select` accepts either a regexp or block. This is handled at the factory level, and the resulting stage is free of conditional logic.
* **no lock-in**: needless to say, Wukong works seamlessly with the Infochimps platform, making robust, reliable massive-scale dataflows amazingly simple. However, wukong flows are not tied to the cloud: they project to Hadoop, Flume or any of the other open-source components that power our platform.

__________________________________________________________________________

<a name="stage"></a>
## Stage

A graph is composed of `stage`s.

* *desc* (alias `description`)

#### Actions

each action 

* the default action is `call`
* all stages respond to `nothing`, and like ze goggles, do `nothing`.

__________________________________________________________________________

<a name="dataflows"></a>
## Workflows

Wukong workflows work somewhat differently than you may be familiar with Rake and such.

In wukong, a stage corresponds to a product; you can then act on that product.

Consider first compiling a c program:

    to build the executable, run `cc -o cake eggs.o milk.o flour.o sugar.o -I./include -L./lib`
    to build files like '{file}.o', run `cc -c -o {file}.o {file}.c -I./include`

In this case, you define the *steps*, implying the products.


Something rake can't do (but we should be able to): make it so I can define a dependency that runs **last** 

### Defining jobs

    Wukong.job(:launch) do
      task :aim do
        #...
      end
      task :enter do
      end
      task :commit do
        # ...
      end
    end

    Wukong.job(:recall) do
      task :smash_with_rock do
        #...
      end
      task :reprogram do
        # ...
      end
    end
    
* stages construct products
  - these have default actions
* hanuman tracks defined order

* do steps run in order, or is dependency explicit?
* what about idempotency?

* `task` vs `action` vs `product`; `job`, `task`, `group`, `namespace`.

### documenting

Inline option (`:desc` or `:description`?)

  ```ruby
      task :foo, :description => "pity the foo" do 
        # ...
      end
  ```

DSL method option

  ```ruby
      task :foo do
        description "pity the foo"
        # ...
      end
  ```

### actions

default action:

  ```ruby
      script 'nukes/launch_codes.rb' do
        # ...
      end
  ```
  
define the `:undo` action:

  ```ruby
      script 'nukes/launch_codes.rb', :undo do
        # ...
      end
  ```      

<a name="file-name-templates"></a>
### File name templates

* *timestamp*: timestamp of run. everything in this invocation will have the same timestamp.
* *user*: username; `ENV['USER']` by default
* *sources*: basenames of job inputs, minus extension, non-`\w` replaced with '_', joined by '-', max 50 chars.
* *job*:  job flow name

<a name="job-versioning-of-clobbered"></a>
### versioning of clobbered files

* when files are generated or removed, relocate to a timestamped location
  - a file `/path/to/file.txt` is relocated to `~/.wukong/backups/path/to/file.txt.wukong-20110102120011` where `20110102120011` is the [job timestamp](#file-naming)
  - accepts a `max_size` param
  - raises if it can't write to directory -- must explicitly say `--safe_file_ops=false`

<a name="job-running"></a>
### running

* `clobber` -- run, but clear all dependencies
* `undo`    -- 
* `clean`   -- 


### Utility and Filesystem tasks

The primitives correspond heavily with Rake and Chef. However, they extend them in many ways, don't cover all their functionality in many ways, and incompatible in several ways.

### Configuration


#### Commandline args

* handled by configliere: `nukes launch --launch_code=GLG20`

* TODO: configliere needs context-specific config vars, so I only get information about the `launch` action in the `nukes` job when I run `nukes launch --help`



__________________________________________________________________________

<a name="dataflows"></a>
## Dataflows


Data flows 

* you can have a consumer connect to a provider, or vice versa
  - producer binds to a port, consumers connect to it: pub/sub
  - consumers open a port, producer connects to many: megaphone

* you can bring the provider on line first, and the consumers later, or vice versa.


<a name="dataflow-syntax"></a>
## Syntax 

**note: this is a scratch pad; actual syntax evolving rapidly and currently looks not much like the following**
   
   read('/foo/bar')         # source( FileSource.new('/foo/bar') )
   writes('/foo/bar')       # sink(   FileSink.new('/foo/bar') )

   ... | file('/foo/bar')   # this we know is a source
   file('/foo/bar') | ...   # this we know is a sink
   file('/foo/bar')         # don't know; maybe we can guess later

Here is an example Wukong script, `count_followers.rb`:

    from :json
    
    mapper do |user|
      year_month = Time.parse(user[:created_at]).strftime("%Y%M")
      emit [ user[:followers_count], year_month ]
    end   
    
    reducer do 
      start{ @count = 0 }
    
      each do |followers_count, year_month|
        @count += 1
      end
    
      finally{ emit [*@group_key, @count] }
    end
    
You can run this from the commandline:

    wukong count_followers.rb users.json followers_histogram.tsv
    
It will run in local mode, effectively doing

    cat users.json | {the map block} | sort | {the reduce block} > followers_histogram.tsv

You can instead run it in Hadoop mode, and it will launch the job across a distributed Hadoop cluster

    wukong --run=hadoop count_followers.rb users.json followers_histogram.tsv

<a name="formatters"></a>
#### Data Formats (Serialization / Deserialization)

* tsv/csv
* json
* xml
* avro
* apache_log
* flat 
* regexp 
* [Tagged Netstrings](http://tnetstrings.org/)
* [ZeroMQ Property Language](http://rfc.zeromq.org/spec:4)

* gz/bz2/zip/snappy 

<a name="data-packets"></a>
#### Data Packets

Data consists of

- record
- schema
- metadata

## Delivery Guarantees

Most messaging systems keep metadata about what messages have been consumed on the broker. That is, as a message is handed out to a consumer, the broker records that fact locally. This is a fairly intuitive choice, and indeed for a single machine server it is not clear where else it could go. Since the data structure used for storage in many messaging systems scale poorly, this is also a pragmatic choice--since the broker knows what is consumed it can immediately delete it, keeping the data size small.

What is perhaps not obvious, is that getting the broker and consumer to come into agreement about what has been consumed is not a trivial problem. If the broker records a message as consumed immediately every time it is handed out over the network, then if the consumer fails to process the message (say because it crashes or the request times out or whatever) then that message will be lost. To solve this problem, many messaging systems add an acknowledgement feature which means that messages are only marked as sent not consumed when they are sent; the broker waits for a specific acknowledgement from the consumer to record the message as consumed. This strategy fixes the problem of losing messages, but creates new problems. First of all, if the consumer processes the message but fails before it can send an acknowledgement then the message will be consumed twice. The second problem is around performance, now the broker must keep multiple states about every single message (first to lock it so it is not given out a second time, and then to mark it as permanently consumed so that it can be removed). Tricky problems must be dealt with, like what to do with messages that are sent but never acknowledged.

So clearly there are multiple possible message delivery guarantees that could be provided:

* At most once—this handles the first case described. Messages are immediately marked as consumed, so they can't be given out twice, but many failure scenarios may lead to losing messages.
* At least once—this is the second case where we guarantee each message will be delivered at least once, but in failure cases may be delivered twice.
* Exactly once—this is what people actually want, each message is delivered once and only once.


__________________________________________________________________________

<a name="design-questions"></a>
## Design Questions

* **filename helpers**: 
  - `':data_dir:/this/that/:script:-:user:-:timestamp:.:ext:'`?
  - `path_to(:data_dir, 'this/that', "???")`?

* `class Wukong::Foo::Base` vs `class Wukong::Foo` 
  - the latter is more natural, and still allows 
  - I'd like 



__________________________________________________________________________
__________________________________________________________________________
__________________________________________________________________________


<a name="references"></a>
## References

<a name="refs-workflow"></a>
### Workflow

* **Rake**

  - [Rake Docs](http://rdoc.info/gems/rake/file/README.rdoc)
  - [Rake Tutorial](http://jasonseifer.com/2010/04/06/rake-tutorial) by Jason Seifer -- 2010, with a good overview of why Rake is useful
  - [Rake Tutorial](http://martinfowler.com/articles/rake.html) by Martin Fowler -- from 2005, so may lack some modernities
  - [Rake Tutorial](http://onestepback.org/index.cgi/Tech/Rake/Tutorial/RakeTutorialRules.red) -- from 2005, so may lack some modernities
  
* **Rake Examples**

  - [resque's redis.rake](https://github.com/defunkt/resque/blob/master/lib/tasks/redis.rake) and [resque/tasks](https://github.com/defunkt/resque/blob/master/lib/resque/tasks.rb)
  - [rails' Rails Ties](https://github.com/rails/rails/tree/master/railties/lib/rails/tasks)
  
* **Thor**

  - [Thor Wiki](https://github.com/wycats/thor/wiki)
  - 
  
* **Chef**

  - [Chef Wiki](http://wiki.opscode.com/display/chef/Home)
  - specifically, [Chef Resources](http://wiki.opscode.com/display/chef/Resources)

* **Other**

  - [**Gradle**](http://gradle.org/) -- a modern take on `ant` + `maven`. The [Gradle overview](http://gradle.org/overview) states its case.

<a name="refs-dataflow"></a>
### Dataflow

* **Esper**

  - Must read: [StreamSQL Event Processing with Esper](http://www.igvita.com/2011/05/27/streamsql-event-processing-with-esper/)
  - [Esper docs](http://esper.codehaus.org/esper-4.5.0/doc/reference/en/html_single/index.html#epl_clauses)
  - [Esper EPL Reference](http://esper.codehaus.org/esper-4.5.0/doc/reference/en/html_single/index.html#epl_clauses)

* **Storm**

  - [A Storm is coming: more details and plans for release](http://engineering.twitter.com/2011/08/storm-is-coming-more-details-and-plans.html)
  - [Storm: distributed and fault-tolerant realtime computation](http://www.slideshare.net/nathanmarz/storm-distributed-and-faulttolerant-realtime-computation) -- slideshare presentation
  - [Storm: the Hadoop of Realtime Processing](http://tech.backtype.com/preview-of-storm-the-hadoop-of-realtime-proce)

* **Kafka**: LinkedIn's high-throughput messaging queue

  - [Kafka's Design: Why we built this](http://incubator.apache.org/kafka/design.html) 

* **ZeroMQ**: tcp sockets like you think they should work

  - [ZeroMQ: A Modern & Fast Networking Stack](http://www.igvita.com/2010/09/03/zeromq-modern-fast-networking-stack/)
  - [ZeroMQ Guide](http://zguide.zeromq.org/page:all)
  - [ZeroMQ: An Introduction](http://nichol.as/zeromq-an-introduction)
  - [Routing with Ruby & ZeroMQ Devices](http://www.igvita.com/2010/11/17/routing-with-ruby-zeromq-devices/)
  - [Ruby bindings for ZeroMQ](http://zeromq.github.com/rbzmq/) and the [Ruby-FFI bindings](http://www.zeromq.org/bindings:ruby-ffi)
  - [Learn ruby ZeroMQ](https://github.com/andrewvc/learn-ruby-zeromq) by @andrewvc
  
* **Other**

  - [Infopipes: An abstraction for multimedia streamin](http://web.cecs.pdx.edu/~black/publications/Mms062%203rd%20try.pdf) Black et al 2002
  - [Yahoo Pipes](http://pipes.yahoo.com/pipes/) 
  - [Yahoo Pipes wikipedia page](http://en.wikipedia.org/wiki/Yahoo_Pipes)
  - [Streambase](http://www.streambase.com/products/streambasecep/faqs/) -- Why is is so goddamn hard to find out anything real about a project once it gets an enterprise version? Seriously, the consistent fundamental brokenness of enterprise product is astonishing. It's like they take inspiration from shitty major-label band websites but layer a whiteout of [web jargon bullshit](http://www.dack.com/web/bullshit.html) in place of inessential flash animation. Anyway I think Streambase is kinda similar but who the hell can tell.
  - [Scribe](http://www.cloudera.com/blog/2008/11/02/configuring-and-using-scribe-for-hadoop-log-collection/)
  - [Splunk Case Study](http://www.igvita.com/2008/10/22/distributed-logging-syslog-ng-splunk/)

<a name="refs-dataflow"></a>
### Messaging Queue

- [DripDrop](https://github.com/andrewvc/dripdrop) - a message passing library with a unified API abstracting HTTP, zeroMQ and websockets.


<a name="refs-dataflow"></a>
### Data Processing

* **Hadoop**

  - [Hadoop]()
 
  
* **Spark/Mesos**

  - [Mesos](http://www.mesosproject.org/)
