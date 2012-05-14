

* [Ruby-Graphviz](https://github.com/glejeune/Ruby-Graphviz.git) Ruby interface to the GraphViz graphing tool
* [Ruby GraphML Parser](https://github.com/willcannings/ruby-graphml.git)



* everything accessible from clean (non-magical) methods.

* inputs and outputs:
  - inputs and outputs become an array of symbols


* You can only have as many macro edges as inputs

* action stage 'ports'
  - a list of names for them
  - can also have an edge going to a 


        _____
        |
        --v--
          |
          |
        __^____^__
        | x  | y |
        |  foo   |
        ----------

create a resource with no action? action with anonymous resource, wired up later?


* connections:

  - action -> action:
  
        act_a -> actb
        
        


    act_a :o1 -> rsrc_x
    act_a :o2 -> rsrc_y
    
    act_b :i  <- act_a
    
    
    
* references:
  - 





