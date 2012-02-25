
Wukong is a toolkit for rapid, agile development of dataflows at any scale.


Here is an example Wukong script, `count_followers.rb`:

    map(:from => :json) do |user|
      emit user[:followers]
    end   
    
    reducer do 
      start{ @count = 0 }
    
      each do |screen_name, followers|
        @count += 1
      end
    
      finally{ emit @count }
    end
    
You can run this from the commandline:

    wukong count_followers.rb users.json followers_histogram.tsv
    
It will run in local mode, effectively doing

    cat users.json | {the map block} | sort | {the reduce block} > followers_histogram.tsv

You can instead run it in Hadoop mode:

    wukong --run=hadoop count_followers.rb users.json followers_histogram.tsv
    
And it will spawn 


## Flow vs Job vs Responder


    
