
## Contract

### Streamer

A Wukong::Streamer must define:

* `process(*record)` -- accepts the array of args returned by the class's `recordize` method

class WebLogParser < Wukong::Streamer
  include Wukong::ApacheLogRecordizer

  def process( date, referer, response, duration, browser_string )
    # ...
  end
class 

You may also define:

#### Things that v1 does

* **after_stream**
* **before_stream**
* **track**       -- called with the record after -- used for logging
* **bad_record!** -- on a bad record
* **monitor**     -- 

#### Things that those are intended to do:

* **this should all be much hook-ier**: 
  - using hook behavior pulled in from active_support

* **easy way to dump to log** --

* The **bad_record!** should have an easy hook

    
    on_bad_record do |junk|
      @bad_record_count += 1  # ?? how do I make it not instance-y
      if @bad_record_count > max_bad_records
      end
    end

  - I can then make a class method that would define hooks:
  
    ```ruby
    die_on_too_many_bad_records(1000)
    ```
    
  
#### Reasons for and against going 1.9+ only in  wukong

**CON**:

* fewer people can use it
* you *must* run JRuby in 1.9 mode

**PRO**:

* 1.9 is WAY THE FUCK BETTER
* you can use ordered hashes
* cause I don't want to have to write/run tests in both.

### Recordizer

* `recordize(blob)` -- accepts a blob of data, and returns an array of params to be processed

  def process(record)
    # ..
  end

... then recordize looks like

  def recordize(blob)
    # ...
    [ record ]
  end

if your process method looks like this

  def process( date, referer, response, duration, browser_string )
    # ...
  end

then recordize loooks like

  def recordize(blob)
    # ...
    [ date, referer, response, duration, browser_string ]
  end


### Emitter (? Sink ?)

### ?? Source ??




## First-class Flume Integration


junk:

        # jRubyDecorator script
        require 'java'
        java_import 'com.cloudera.flume.core.EventSinkDecorator'
        java_import 'com.cloudera.flume.core.Event'
        java_import 'com.cloudera.flume.core.EventImpl'

        module FlumeConnector

          # FIXME: need to call before_stream in initializer?? open??

          def append(e)
            body = String.from_java_bytes e.getBody

            record = recordize(body.chomp) or return

            process(*record) do |output_record|
              emit(record, e)
            end
          end

          def emit(record, e)
            out_line = record.to_flat.join("\t")
            out_buf  = out_line.to_java_bytes
            super EventImpl.new(out_buf, e.getTimestamp, e.getPriority, e.getNanos, e.getHost, e.getAttrs )
          end

          # FIXME: need to call after_strem in ?close?
        end



        class ReverseDecorator < EventSinkDecorator
          # def initialize(context, *args)
          #   super( nil )
          # end
        end

        Wukong::Script.new(ReverseStreamer, nil).run
