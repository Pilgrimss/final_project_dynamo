# Interface
## Get(key)
### Description
- Locates the objects replicas associated with the key in the storage system 
- Returns a single list of objects with conflicting versions along with a *context* 
### Implementation
- Any node can act as a coordinator for a read request
- The coordinator requests all existing versions of data for that key from the $N$ highest-ranked reachable nodes
- then waits for $R$ responses before returning the result to the client 
- If multiple versions gathered: (TODO)
    - **Read Repair**: If stale versions were returned in any of the responses, the coordinator updates those nodes with the latest version
- If too few replies were received within a given time bound, fail the request
## Put(key, context, object)
### Description
Determines where the replicas of the object should be placed based on the associated key, and writes the replicas to disk.
### Implementation
- Only nodes in the key's preference list can coordinate 
- The coordinator generates a vector clock for the new version and writes the new version locally
- then sends the new version to the $N$ highest-ranked reachable nodes in the preference list of the *key*
- If at least $W-1$ nodes respond then the write is considered successful
## Context 
- Context includes information such as the version of the object
- Context is stored along with the object
## Hash
- Dynamo applies a MD5 hash on the key to generate a 128-bit identifier, which is used to determine the storage nodes to serve the key
# Client-Driven Coordination

# Partitioning
Dynamo's partitioning scheme relies on a variant of **consistent hashing** to distribute the load across multiple storage hosts.
- The output range of a hash function is treated as a fixed **ring**
- Each node is assigned to multiple positions on the ring
    - A **virtual node** looks like a single node in the system
    - Each node can be responsible for more than on virtual node
- Each data object is assigned to a node by 
    - hashing its key to yield its position $p$ on the ring
    - walk clockwise on the ring to find the first $N-1$ successors
- Each node is responsible for the region between it and its $N^{th}$ *predecessor* node on the ring 

## Partition Scheme
### $Q/S$ random tokens per node and equal sized partitions
- The hash space is divided into $Q$ equally sized ranges(partitions)
- Each node is assigned $Q/S$ random tokens, where $S$ is the number of nodes in the system 
- The tokens are used to map values in the hash space to the ordered list of nodes 
- A partition is placed on the first N unique nodes that are encountered while walking the consistent hashing ring clockwise from the end of the partition
- When a node leaves the system, its tokens are randomly distributed to the remaining nodes
- When a node joins, it steals tokens from nodes in the system 
# Replication
>**Preference List**: The List of nodes that is responsible for storing a particular key $k$ 
>
>Coordinator: A node handling a read or write operation, typically the first in the preference list

- Each data object is replicated at $N$ hosts ($N$ is a configured parameter)
- Each key $k$ is assigned to a coordinator node which 
    - stores the key locally
    - and replicates it at the $N-1$ clockwise successor nodes in the ring 
- **Preference List**: The List of nodes that is responsible for storing a particular key $k$
    - Every node in the system can determine the preference list for any particular key $k$
    - A preference list can contain more than $N$ nodes to tolerate node failure
    - The preference list is ensured to contain only distinct physical nodes. 
# Versioning (TODO)
- Versioning is introduced to solve conflicts. We use vector clock to capture causality between different version of the same object. 
- **Vector Clock**:
    - Every Object should has a vector clock for every version. (Note in dynamo each update is an immuatble new version)
    - Format of vector clock is [(node, counter),(node, counter)...]
    - comparison: If the counters on the first object’s clock are less-than-or-equal to all of the nodes in the second clock, then the first is an ancestor of the second and can be forgotten. Otherwise conflict.
    - To avoid oversized pairs list, a timestamp is associated with each pair and the pair will be dumped if len(list) > 10. (Note deleting will not cause inconsisitency but higher chance of reconcile by client)
    - How do client reconcile? If shopping cart, union all versions.(not deleting any potential items)

# Failure Handling
## Hinted Handoff (TODO)
## Replica Synchronization
### Merkle Tree
> Merkle tree is a hash tree where leaves are hashes of the values of individual keys.
> Parent nodes higher in the tree are hashes of their respective 

Dynamo uses merkle tree for anti-entropy:
- Each node maintains a separate Merkle tree for each key range (the set of keys covered by a virtual node) it hosts. 

## anti-entropy 
- **Merkle Trees in Nodes**
    - For each key range obtained by a node, we need a separate Merkle Tree. That is saying, each node matains a list of Merkle trees. For ex, if Node C has authroity over data range from (A,B] and (B,C], and Node D has (B,C], (C,D] we will only need to compare Merkle Trees of (B,C]. (TODO Maybe there are ways provided by the imported Merkle, need to verify).
    - Detail implementations are: 
        - Nodes need to send compare Tree request along with the key range and the Trees. 
        - When a Node received a TreeCompare Request. For each key range to compare, start from the root and go through all the unequal hash till leaf. Then decide which version of the leaf is better and update. Decision made upon the vector clock. 

# Membership 
- Each node maintains a view of membership
- When a node starts, it chooses a set of tokens and maps nodes to their respective token sets.
- Initially, it only persists the local node and its token set.
- It communicate with *seeds* to reconcile the membership view. 
- Seeds broadcast the membership change to other nodes. 
- Seeds can obtained from static configuration. 

# Consistency Protocol
- $R$: the minimum number of nodes that must participate in a successful read operation
- $W$: the minimum number of nodes that must participate in a successful write operation
- Quorum-like: $R+W>N$
- Better latency: set $R, W$ less than $N$

# Config Parameters
- $N$: Number of replication hosts
- $R$: the minimum number of nodes that must participate in a successful read operation
- $W$: the minimum number of nodes that must participate in a successful write operation











