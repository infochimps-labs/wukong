# General

* There is this awkward and unstated need that a dataflow set its output using `set_output(sink)`.
** `Wukong::LocalRunner` has this hard-coded to `sink(:test_sink)` - broke.

* The `map` method used in dataflow; from whence does it come? Found it in `wukong/processor.rb`; does this fit better in `wukong/widget`?

* A "null" processor AND an "as_is" processor don't both make sense. I think, conceptually, that `Wukong::Processor::Null` === `Wukong::Processor::AsIs` and we should choose only one. A "null" sink might be better suited for the purporse of "rejecting all records." And this already exists in `widget/sink.rb`. 
** There are also "all" and "none" filters in `widget/filter.rb`.

* `Wukong::Filter::All` and `Wukong::Filter::None` are not registered. Should they be? Do they work as they should, because it appears not...
** Are these necessary as `Wukong::Processor::Null` and `Wukong::Processor::AsIs` already exist?

* In `Wukong::Runner` why do I have to specify sinks/sources wih a name? are these ever referenced/used in any context later? Seems that the runner might not need names...

* Is there a reason wukong has a config directory with a very outdated yaml file?

* The Guardfile has a lot of debuggy cruft. Fixit.

* So many rad 80's references.

# Specs

* DONE ~The graphviz spec could be made into an argument in spec helper, whether to run the file or not.~

* There should be a cleanup phase after specs have run to delete artifacts. 


