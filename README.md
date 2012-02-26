
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






    
    
## Rapid development



    wukong --map
