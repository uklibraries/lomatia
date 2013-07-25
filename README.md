Lomatia
=======

Lomatia is a storage manager for the AIP and DIP store of the
Kentucky Digital Library.  It is used to move AIPs and DIPs
across various storage nodes to prevent any particular node
from getting too full.  It is policy-agnostic and is intended
to be directed by higher-level tools to manage the nodes.  In
return, Lomatia allows the higher-level tools to ignore some
of the low-level details of the storage nodes.

Lomatia maintains information about a PairTree hierarchy spread
across several storage nodes and linked by symlinks, indicating 
for each bag in the hierarchy its current node (and its destination
node, if it or an ancestor branch is in transit).  All commands
return JSON output and are expected to run asynchronously. 
However, Lomatia is intended for very low-volume use and may not
handle rafts of concurrent requests efficiently.

Usage
-----

Lomatia's commands take the form

```
lomatia <verb> <option1>="<value1>" <option2>="<value2>" ...
```

The available verbs are:

* `getCollections` (idempotent, safe)
* `getNodes <collection_id>` (idempotent, safe)
* `getPathState <collection_id> <path>` (idempotent, safe)
* `movePath <collection_id> <target_node_id> <path>` (idempotent, unsafe)
* `addCollection <collection_id>` (non-idempotent, unsafe)
* `addNode <collection_id> <node_id>` (non-idempotent, unsafe)
* `removeCollection <collection_id>` (idempotent, unsafe)
* `removeNode <collection_id> <node_id>` (idempotent, unsafe)
* `setMaster <collection_id> <node_id>` (idempotent, unsafe)
* `syncPaths <collection_id> <node_id> <partial_path>` (idempotent, unsafe)

Example
-------

$ lomatia getCollections
```json
{"collections": ["aips", "dips"]}
```

$ lomatia getNodes collection_id="aips"
```json
{"nodes": ["library_aips_1", "library_aips_2", "library_aips_3"]}
```

$ lomatia getPathState collection_id="aips" path="pairtree_root/xt/7p/zg/6g/2p/81"
```json
{"path": {
  "fs_path": "pairtree_root/xt/7p/zg/6g/2p/81", 
  "node_id": "library_aips_1", 
  "status": "stable"}}
```

$ lomatia movePath collection_id="aips" target_node_id="library_aips_2" path="pairtree_root/xt/7p/zg/6g/2p/81"
```json
{"path": {
  "fs_path": "pairtree_root/xt/7p/zg/6g/2p/81", 
  "node_id": "library_aips_1", 
  "status": "in_transit", 
  "source_node_id": "library_aips_1", 
  "target_node_id": "library_aips_2"}}
```

$ lomatia movePath collection_id="aips" target_node_id="library_aips_3" path="pairtree_root/xt/7p/zg/6g/2p/81"
```json
{"errors": ["Path already in transit"], 
 "path": {
   "fs_path": "pairtree_root/xt/7p/zg/6g/2p/81", 
   "node_id": "library_aips_1", 
   "status": "in_transit", 
   "source_node_id": "library_aips_1", 
   "target_node_id": "library_aips_2"}}
```

... time passes ...

$ lomatia getPathState collection_id="aips" path="pairtree_root/xt/7p/zg/6g/2p/81"
```json
{"path": {
  "fs_path": "pairtree_root/xt/7p/zg/6g/2p/81", 
  "node_id": "library_aips_2", 
  "status": "stable"}}
```

Representation
--------------

A _node_ is a network share.  Nodes are aggregated into _collections_.  For example, at
the University of Kentucky we store archival packages (AIPs) and access packages (DIPs) on 
different network shares.  Since a node is just a filesystem, it has many _paths_.  Our nodes are
currently laid out as [PairTree](https://wiki.ucop.edu/display/Curation/PairTree) hierarchies
terminating in [BagIt](https://wiki.ucop.edu/display/Curation/BagIt) bags.  Our bags are assigned
[ARK](https://wiki.ucop.edu/display/Curation/ARK) identifiers with a length of 12 characters.
Hence a path on a node which does not descend into a bag has a maximum depth of 8 directories:

```
pairtree_root/xt/70/5q/4r/jf/6g/xt705q4rjf6g
```

For each collection of nodes, we designate one node as the _master_.  This node must maintain a
complete PairTree hierarchy of all bags in the collection.  At the bottom of the hierarchy, the node 
must either hold a bag directly or a symlink to the bag on another node in the collection.  A non-master
node may hold a gappy PairTree hierarchy that only includes paths to bags stored on that node.

Installation
------------

This software is still in development and is closely tied to a particular institution's needs.
I'm offering it under the MIT license in case you find anything in it useful, but I don't expect
to scratch any universal itches with this program.
