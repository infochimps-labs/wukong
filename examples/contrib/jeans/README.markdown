Notes and scripts from a talk by Fredrik Möllerstrand, (@lenbust / http://fredrikmollerstrand.se) with some modifications by @mrflip

See http://bit.ly/6ItaHI and forks of that gist!

Wukong who?
-----------

Here be some notes from my talk on [Wukong](http://github.com/mrflip/wukong) at the January meetup of [Got.rb](http://www.meetup.com/got-rb/).

Wukong is a framework for writing Hadoop jobs in Ruby. Other such frameworks are [MRToolkit](http://code.google.com/p/mrtoolkit/) (which is also written in Ruby and which I have not tried it) and [Dumbo](http://github.com/klbostee/dumbo) (which is written in Python and which I love dearly). You could also write your jobs in Java(!) or as bare scripts hooked into [Hadoop Streaming](http://hadoop.apache.org/common/docs/current/streaming.html), but that would be nuts.

Wukong gives you the option of treating your data as a stream of lines or as a stream of fields or lightweight objects. My forenoon's experience of Wukong covers only the basic text streaming so we'll skip the structured data and interpret the data as dumb chunks of text.

The data, which I regrettably can not share with you on the wider interwebs, are records of jeans ordered by stores from a central jean distributor. There is one line per order, and each order is for a specific market and for a specified number of jeans for each size. There are 13 sizes in total.

An example of which:

	SS10	vaxjobutiken	2010-01-10 10:45:54	sweden	Storgatan 64 	VÄXJÖ	352 30	SWEDEN	retailer	120664	L34	0	0	0	0	0	1	1	1	2	2	1	1	0
	SS10	vaxjobutiken	2009-01-10 10:45:54	sweden	Storgatan 64 	VÄXJÖ	352 30	SWEDEN	retailer	120721	L32	0	0	0	0	0	1	2	2	2	1	1	1	0
	SS09	kubic	2010-01-10 13:33:37	spain	NULL	NULL	NULL	NULL	retailer	120571	L34	0	0	0	0	0	0	0	1	1	1	1	1	0

The integers at the end there describe how many of each jean size was ordered.

We'll use Wukong to summarize the orders for each country. The job is run locally (as oppposed to on Hadoop) to avoid any startup overhead.

sizes.rb
--------
        $> ruby sizes.rb --run=local data/orders.tsv data/sizes

        require 'rubygems'
        require 'wukong'
        module JeanSizes
          class Mapper < Wukong::Streamer::RecordStreamer
            def process(code,model,time,country,j1,j2,j3, n1,n2,c1, venue,n3,n4, *sizes)
              yield [country, *sizes] if sizes.length == 13
            end
          end

          class JeansListReducer < Wukong::Streamer::ListReducer
            def finalize
              return if values.empty?
              sums = []; 13.times{ sums << 0 }
              values.each do |country, *sizes|
                sizes.map!(&:to_i)
                sums = sums.zip(sizes).map{|sum, val| sum + val }
              end
              yield [key, *sums]
            end
          end
	end

	Wukong::Script.new(JeanSizes::Mapper, JeanSizes::JeansListReducer).run

*JeanSizes::Mapper#process*, being a RecordStreamer, is given one set of input fields to work with at a time. It picks out the good parts, namely the country at index 3 and the integers at index 11 through 23. The rest of the fields are unimportant and just given placeholder names.

The country is promoted to key and the sizes array is value. These are yielded as a list – since the reducer is a list reducer!

*JeanSizes::Reducer#finalize* is given the key ('sweden' for example) and a list of lists of integers. These are (over)cleverly summarized into one list, *sums*.

The output of these two steps is a much smaller data set containing the number of jeans of each size purchased, broken down by market.

An example of which:

	sweden  807     1443    2215    2460    2316    2077    2392    2563 3068    2356    2051    1016    255
	switzerland     90      201     731     886     585     325     404 624     770     721     635     295     41
	unitedstates    446     1103    2007    2442    2863    2879    3920 3687    5588    4256    5299    3777    1842


That's all peachy, but what if I'd like to compare the relative amount of large jeans bought in Sweden with those bought in the US? A working hypothesis might be that swedes wear smaller jean sizes than do americans. Well, let's normalize the data and see what we can make of it.

normalize.rb
------------
        $> ruby normalize.rb --run=local data/sizes.tsv data/normalized_sizes.tsv

        require 'rubygems'
        require 'wukong'
        require 'active_support/core_ext/enumerable' # for array#sum

	module Normalize
	  class Mapper < Wukong::Streamer::RecordStreamer
	    def process(country, *sizes)
	      sizes.map!(&:to_i)
	      sum = sizes.sum.to_f
	      normalized = sizes.map{|x| 100 * x/sum }
	      s = normalized.join(",")
	      yield [country, s]
	    end
	  end
	end

	Wukong::Script.new(Normalize::Mapper, nil).run

Again we're dealing with a line streamer. The normalization divides each jean size by the total number of jeans sold in that country and scales it up by 100 to make the figures into proper percentages.

You will also notice that I join the list of normalized values with a comma. Why in the name of Buddha would I do that? Bear with me.

Parts of the output looks like so:

	sweden	1.01922538870458,4.06091370558376,8.19776969503178,9.41684319916863,12.2626803629242,10.2442143970582,9.56073384227987,8.30169071505656,9.25696470682282,9.83252727926776,8.85327151364963,5.76761661137536,3.22554858307686
	switzerland	0.64996829422955,4.67660114140774,10.0665821179455,11.429930247305,12.2067216233354,9.89220038046925,6.40456563094483,5.15218769816107,9.27393785668992,14.0456563094483,11.5884590995561,3.1864299302473,1.42675967025999
	unitedstates	4.59248547707497,9.41683911341594,13.2114986661348,10.6110847939365,13.9320352040689,9.19245057219078,9.77336757336259,7.17794011319155,7.13804881697375,6.08840908524271,5.0038644693211,2.75000623301503,1.11196988207136


Data visualized
---------------

In the words of the late great R. Dingly, '*data not visualized is not data*'.

Let's put our hypothesis to work and graph this. The quickest path to a graph just happens to be Google Charts, and here's
[a graph comparing jeans sizes bought in Sweden and the US ](http://chart.apis.google.com/chart?cht=bvg&chd=t:1.01922538870458,4.06091370558376,8.19776969503178,9.41684319916863,12.2626803629242,10.2442143970582,9.56073384227987,8.30169071505656,9.25696470682282,9.83252727926776,8.85327151364963,5.76761661137536,3.22554858307686|4.59248547707497,9.41683911341594,13.2114986661348,10.6110847939365,13.9320352040689,9.19245057219078,9.77336757336259,7.17794011319155,7.13804881697375,6.08840908524271,5.0038644693211,2.75000623301503,1.11196988207136&chds=0,20&chs=800x375&chdl=Sweden|USA&chco=eecc00,00eedd).

It seems that americans buy smaller sizes while swedes go for larger breeches, which is quite the opposite of what we thought.

As someone in the crowd pointed out during the meet, this might be due to the fact that the particular brand of jeans under scrutiny here has become mainstream in Sweden while it is still mostly worn by thin punk-rockers in the states. Again the the words of Mr. Dingly echo so true: '*data is nothing without interpretation*'.

Chaining Runs
-------------

**Local Mode**: If you're running in local mode, chaining is straightforward: just use a single dash '-' as the output file, and wukong will leave its output on STDOUT rather than dumping to a file on disk. (NOTE: this is only true as of wukong v1.4.5.) (OTHER NOTE: if you've already written a file named '-' to disk, use "rm -- -" to remove it).

       ./sizes.rb --run=local data/orders.tsv -  | ./normalize.rb --run=local - data/normalized_sizes

For anything fancier (or for earlier versions of wukong): all the local runner does is to take your script and run

       cat input.tsv | myscript.rb --map [..args..] | sort | myscript.rb --reduce [..args..] > output.tsv

You can do the chaining by hand:

       cat input.tsv | myscript.rb --map [..args..] | sort | myscript.rb --reduce [..args..] | whatever | ./anotherscript.rb --map | sort | ./anotherscript --reduce > output.tsv

**Hadoop Mode**: Wukong doesn't let you chain jobs or define workflows.  There are tools out there that enable this, but there are no mature solutions that I [@mrflip] know of.

In closing
----------

This has been a quick rundown of Wukong as I know it after a few hours of use. Improvements can certainly be made and I welcome any and all comments. Please consider amending the code in this presentation by forking [this gist](http://gist.github.com/278043).

Also, you should follow me on twitter: [@lenbust](http://twitter.com/lenbust).

Postscript
__________

The LineReducer used in sizes.rb is perfect for a small, local run such as this one.  However, for large amounts of data it's best to avoid the ListReducer, as it collects every single record in memory before finalizing.

You can instead use an Accumulating reducer directly. Compare this class with the JeansListReducer above and you'll see we are applying the same basic workflow, just in explicitly separated steps.

          class JeansAccumulatingReducer < Wukong::Streamer::AccumulatingReducer
            attr_accessor :sums

            # start the sum with 0 for each size
            def start! *_
              self.sums = []; 13.times{ self.sums << 0 }
            end

            # accumulate each size count into the sizes_sum
            def accumulate country, *sizes
              sizes.map!(&:to_i)
	      self.sums = self.sums.zip(sizes).map{|sum, val| sum + val }
	    end

	    # emit [country, size_0_sum, size_1_sum, ...]
	    def finalize
	      yield [key, *sums]
	    end
	  end
