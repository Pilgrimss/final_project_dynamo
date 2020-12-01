# 11.27
## System storage
local memory

## Client Interface

get(key): no versioning with context

put(key, object)

The requests are routed through a load balancer
## Server
merkle tree 
### Client Driven Coordination
- Client picks a random dynamo node from *seeds* and downloads the dynamo membership state  
- Client determines the set of nodes form the preference list for any given key

### Partition
#### Hash Space

### Request coordination component
state machine

hash function 

Nodes in the system are **virtual** nodes, a **physical** node can be assigned to multiple virtual nodes
 