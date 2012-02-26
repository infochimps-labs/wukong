### Syntax


* source and sink should be late-bound, and not have `run` methods. Instead, something like

        stream(:a) | foo | bar | baz

  flow.run then binds source and sink and is the one to invoke `foo.call` on each record (and not the source, which is the case currently)

* give `flow` the idea of a ?channel? ?stream?? Let's go with stream atm.
  - you call run with the handle to a concrete source and the handle to one of flow's streams.
  - a split takes multiple *streams* (not stages) as its arguments

* Graph assembly is not delayed, but maybe? it should be. (I'm not as sure about this any more -- we'll see)

  - the magic methods on flow should not produce objects directly -- it should produce a graph whose DNA can later give birth to those objects.
  - so have the magic stage factory methods produce graph proxies, not direct classes.

  - the current implementation produces weird things like

        x = foo | bar | baz
        y | x                # connects y's next_stage to baz, not foo

    the return value of a `|` should be the stream, not the last object in the stream

  - this will also centralize the 'pass in a proc, or a streamer instance, or a whatever' DWIM-ness; demands that stages have exactly one signature.

* registration is lame.
  - make it explicit (getting rid of the `inherited()` magic):

        class Foo < Wukong::Streamer::Base
          named :foo
        end

  - the handle should defines a star-args method with the given name on `Wukong::Flow`; the above would define

  - Names of some classes would have to change where there's a collision.


* I'm not sure which I prefer:
  - `Wukong::Limit`           -- simplest. puts lots of stuff in flat namespace. Have to come up with clever names (eg `Iter` for `Enumerable`)
  - `Wukong::LimitStreamer`   -- flat namespace. Lets you have direct-analogue names (`EnumerableStreamer`)
  - `Wukong::Streamer::Limit` -- responsibly namespaced. File tree is manageable. Still have to come up with clever names (eg `Iter` for `Enumerable`).

  I went with the last one because I believe most interaction will be through the sugar methods, so by the principle of 'light, predictable magic or no magic' I go with proper deep namespacing.

### Streamers

**module inclusion vs. class inheritance**

For example, the limit vs. the counter streamers


**monitoring and logging**

periodic monitor can now be its own thing yay.

**are things resettable?** 

I vote no.


### Group

We need
* a sideband connection that all things respond to besides `#call` -- `#tell`?
* specifically, a way to

Partion fields vs key fields -- is this part of the schema? (see below)



### Data model

* want to eg pass data around as an array, but know its field names on output
  - ask prior stage what the schema is? Method `ask` would return answer if known, passes to previous if not
  - Or maybe am always told schema; since this is the avro way I think let's do that


### Hadoop integration

* **runner** -- should be decoupled (for eventual move into swineherd).
  - Flow graph is responsible for advising on script names, input files, output file, group keys
  - see graph projection, below

* **Hadoop-style counters** -- serialized to STDOUT

### Hooks

### graph binding

Only hazy ideas right now on how this works.

But the idea is that the executor(s) should be able to claim their part of the graph.

    input | from_json | cleaner | splitter | m_output
      | sort |
    r_input | group | red | output

The local runner should bind

    input                               stdin < cat [input_filename]
    from_json | cleaner | splitter      Wukong.flow(:mapper) in wukong script.rb --mode=mapper
    m_output                            stdout
    sort                                sort
    r_input                             stdin
    group                               group in wukong script.rb --mode=mapper
    red                                 Wukong.flow(:reducer) in wukong script.rb --mode=reducer
    output                              stdout > output_filename

the hadoop runner should bind

    input                               hadoop param
    from_json | cleaner | splitter      Wukong.flow(:mapper) in wukong script.rb --mode=mapper
    sort                                [assumed]
    group                               group in wukong script.rb --mode=mapper
    red                                 Wukong.flow(:reducer) in wukong script.rb --mode=reducer
    output                              hadoop param

a unix_pipes runner might

    input                               directly read
    from_json | cleaner | splitter      Wukong.flow(:mapper) in wukong script.rb --mode=mapper
    sort                                using pipe to `sort`
    group                               group in wukong script.rb --mode=mapper
    red                                 Wukong.flow(:reducer) in wukong script.rb --mode=reducer
    output                              directly written

### Rack compatibility

Once this starts to firm up, we should take a look at what it would take to make an adapter layer to turn any flow into a Rack or Goliath middleware.
