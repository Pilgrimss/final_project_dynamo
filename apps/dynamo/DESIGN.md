# Interface
## Get(key)
### Description
- Locates the objects replicas associated with the key in the storage system 
- Returns a single list of objects with conflicting versions along with a *context* 
### Implementation
- The coordinator requests all existing versions of data for that key from the $N$ highest-ranked reachable nodes
- then waits for $R$ responses before returning the result to the client 
- If multiple versions gathered: (TODO)
    - **Read Repair**: If stale versions were returned in any of the responses, the coordinator updates those nodes with the latest version
- If too few replies were received within a given time bound, fail the request
## Put(key, context, object)
### Description
Determines where the replicas of the object should be placed based on the associated key, and writes the replicas to disk.
### Implementation
- The coordinator generates a vector clock for the new version and writes the new version locally
- then sends the new version to the $N$ highest-ranked reachable nodes in the preference list of the *key*
- If at least $W-1$ nodes respond then the write is considered successful
## Context 
- Context includes information such as the version of the object
- Context is stored along with the object
## Hash
- Dynamo applies a MD5 hash on the key to generate a 128-bit identifier, which is used to determine the storage nodes to serve the key
## load Balancer
- Any storage node in Dynamo is eligible to receive client get and put operations
- A client route its request through a generic load balancer that will select a node based on load information
    - If The node receives the request is not in the preference list of the key
        - the node will forward the request to the first among the top $N$ nodes in the preference list
    - Optimization: the coordinator for a write is chosen to be the node that relied fastest to the previous read operation which is stored in the context information of the request 
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
### T random tokens per node and equal sized partitions
- The hash space is divided into $Q$ equally sized ranges
- Each node is assigned $T$ random tokens 
- $Q >> N$ and $Q >> S * T$
- Each node is assigned T tokens
    - chosen uniformly from the hash space
- The tokens of all nodes are ordered according to their values in the hash space
- Each two consecutive tokens define a range
- The last token and the first token form a range the "wraps" around from the highest value to the lowest value in the hash space
- The ranges vary in size
 
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

# Consistency Protocol
- $R$: the minimum number of nodes that must participate in a successful read operation
- $W$: the minimum number of nodes that must participate in a successful write operation
- Quorum-like: $R+W>N$
- Better latency: set $R, W$ less than $N$

# Config Parameters
- $N$: Number of replication hosts
- $R$: the minimum number of nodes that must participate in a successful read operation
- $W$: the minimum number of nodes that must participate in a successful write operation











