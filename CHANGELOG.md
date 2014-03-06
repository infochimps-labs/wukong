## Version 3: Complete rewrite

Version 3 is a complete refresh of Wukong. There will probably be a compatibility layer.

The new version is highly modularized, and built on top of the Hanuman dataflow toolkit.

The central idea is to assemble your jobs as a stack of decoupled stages. These stages are agnostic to whether they are running in a hadoop batch job, from the command line, in a Flume decorator, or as middleware in a Hanuman request stack.
