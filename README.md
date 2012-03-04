
Wukong is a toolkit for rapid, agile development of dataflows at any scale.


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
    

## A Dataflow is a Data Flow


## Syntax 
   
   read('/foo/bar')         # source( FileSource.new('/foo/bar') )
   writes('/foo/bar')       # sink(   FileSink.new('/foo/bar') )

   ... | file('/foo/bar')   # this we know is a source
   file('/foo/bar') | ...   # this we know is a sink
   file('/foo/bar')         # don't know; maybe we can guess later

#### Serialization / Deserialization

   from_tsv
   parse(:tsv)

* gz/bz2/zip/snappy ; tsv/csv/json/xml/avro/netbinary ; apache_log ; flat ; regexp ; 

## Data

Data consists of

- record
- schema
- metadata


   
## Catalog


### Sources / Sinks

Sources have a `continuous`(?) flag: keep reading on end of stream, or finish? (or, maybe they always are reading, and the EOS is an event that might or might not trigger a shutdown)

* stdin / stdout / stderr
* file (filesystem, s3, hdfs) - tail/read; write
  - source: poll for file pattern
  - sink:   roll output filename
* hanuman log (hierarchical)
* database 
  - source: must specify query
  - sink:   must specify [ key / identifying fields ; update|create ; payload fields ]
* http request
* http stream
* socket / rpc
* jabber / amqp / twitter
* syslog / syslog-ng
* exec file


### Switch

Uses record field to choose output


## Internals

The fundamental principle of Hanuman is *don't do the thing, coordinate the boxes that do the thing*. Wukong is a pragmatic collection of dataflow primitives that let you shit done quickly, nimbly and readably. They each emphasize scalability, readability and rapid development (and not, for instance, performance or universality).

Wukong/Hanuman are chiefly concerned with three specific types of graphs:

* **dataflow**   -- chains of simple modules to handle continuous data processing -- coordinates Flume, Unix pipes, ZeroMQ, Esper.
* **workflows**  -- episodic jobs sequences, joined by dependency links -- comparable to Rake, Azkaban or Oozie.
* **map/reduce** -- Hadoop's standard *disordered/partitioned stream > partition, sort & group > process groups* workflow. Comparable to MRJob and Dumbo.

In addition, wukong stages may be deployed into

* **http middlware**: lightweight distributed API handlers -- comparable to Rack, Goliath or Twisted.
* **queue workers**: asynchronously triggered jobs -- 


## Questions

* **filename helpers**: 
  - `':data_dir:/this/that/:script:-:user:-:timestamp:.:ext:'`?
  - `path_to(:data_dir, 'this/that', "???")`?
