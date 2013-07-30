Lomatia
=======

Lomatia is a storage manager for the AIP and DIP store of the
Kentucky Digital Library.  It is used to move AIPs and DIPs
across various storage nodes to prevent any particular node
from getting too full.  It is policy-agnostic and is intended
to be directed by higher-level tools to manage the nodes.  In
return, Lomatia allows the higher-level tools to ignore some
of the low-level details of the storage nodes.

In particular, Lomatia provides the following commands:

* `replant --path <pairtree_path> --source <source> --target <target>`

This command determines whether its path argument is the root of 
a [BagIt](https://wiki.ucop.edu/display/Curation/BagIt) bag or just
a directory, and enqueues an appropriate worker into a job queue
to handle the move later.

The bag handler rsyncs the given bag from one storage node to 
another, moves the original out of the way, creates a symlink
to the new copy, and finally deletes the original bag.

The path handler runs the command `replant` on each of the
path's children, using the same `<source>` and `<target>` 
arguments as it received.

* `check_fixity --log <log_file> --path <pairtree_path> --node <node>`

This command runs a BagIt validity check on each bag in the 
indicated part of the tree, logging the results in a log file.

Installation
------------

This software is still in development and is closely tied to a 
particular institution's needs.  I'm offering it under the MIT license 
in case you find anything in it useful, but I don't expect to scratch 
any universal itches with this program.
