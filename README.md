Lomatia
=======

Lomatia is a storage manager for the AIP and DIP store of the
Kentucky Digital Library.  It is used to move AIPs and DIPs
across various storage nodes to prevent any particular node
from getting too full.  It is policy-agnostic and is intended
to be directed by higher-level tools to manage the nodes.  In
return, Lomatia allows the higher-level tools to ignore some
of the low-level details of the storage nodes.

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
