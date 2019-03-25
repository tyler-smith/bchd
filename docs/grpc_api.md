# Bitcoin Cash gRPC API

### What
This is a proposal for a new RPC API. We are planning on implementing something like this in bchd, but other node implementations
may want to implement it as well so we have compatibility between implementations. This propsal is made public to allow other people
to comment and suggest edits. 

### Why
The JSON-RPC API which is currently implemented in bchd and other node software isn't great. In addition to being somewhat inefficient, 
it typically requires custom serialization and deserialization code to be written which increases the codebase's complexity and makes
modififying the API somewhat difficult. In bchd, to add a new API call it requires modifying hundreds of lines of code across eight 
different files across mutltiple packages. Futher, JSON-RPC doesn't support streaming so you need to implement a separate API (bchd uses
websockets) to get streaming functionality. Bitcoind based nodes use ZMQ which is really a terrible choice since it requires clients to
import a massive C dependency just to use the API. 

### Why gRPC
gRPC is much more modern RPC framework which is faster and more optimized than JSON-RPC. Rather than sending JSON strings over HTTP/1 it uses a 
binary format over HTTP/2. We can define the schema in protobuf making it easy to import into other clients and other languages. Creating a
client implementation is simply a matter of grabbing the .proto file and compling to your preferred language. The compiler will build
the full client code including serialization/deserialization code. gRPC also supports streaming which means we don't need separate
APIs to get the functionality we want. It also supports TLS out of the box. Something which JSON-RPC does not do.

### Why continued
A goal of bchd is to make it easier for the full node software to serve applications such as wallets and explorers without requiring separate
software to be run on top of the ful node. This would mean every full node would potentially be able to serve applications if the correct
runtime options are set and the API made public.

## Specification // TODO still a WIP
```protobuf

syntax = "proto3";

package bchrpc;

// PublicRPC contains a set of RPCs that can be exposed publically via
// the command line options. The idea is this service would be separate
// from the main service so that applications can connect to it without
// gaining access to the other RPCs which control node operation. This
// service could be authenticated or unauthenticated.
service PublicRPC {
	
	// Get info about the mempool.
	rpc GetMempoolInfo(GetMempoolInfoRequest) returns (GetMempoolInfoResponse) {}
	
	// GetBlockchainInfo info about the blockchain including the most recent
	// block hash and height.
	rpc GetBlockchainInfo(GetBlockchainInfoRequest) returns (GetBlockchainInfoResponse) {}
	
	// Get info about the given block.
	rpc GetBlockInfo(GetBlockInfoRequest)returns (GetBlockInfoResponse) {}
	
	// Get a block.
	rpc GetBlock(GetBlockRequest) returns (GetBlockResponse) {}
	
	// Get a serialized block.
	rpc GetRawBlock(GetRawBlockRequest) returns (GetRawBlockResponse) {}
	
	// **Requires TxIndex**
	// Get a transaction given its hash.
	rpc GetTransaction(GetTransactionRequest) returns (GetTransactionResponse) {}
	
	// **Requires TxIndex**
	// Get a serialized transaction given its hash.
	rpc GetRawTransaction(GetTransactionRequest) returns (GetRawTransactionResponse) {}
	
	// **Requires AddressIndex**
	// Returns the transactions for the given address. Offers offset,
	// limit, and from block options.
	rpc GetAddressTransactions(GetAddressTransactionsRequest) returns (GetAddressTransactionsResponse) {}
	
	// **Requires TxIndex and AddressIndex**
	// Returns all the unspent transaction outpoints for the given address.
	// Offers offset, limit, and from block options.
	rpc GetAddressUnspentOutputs(GetAddressUnspentOutputsRequest) returns (GetAddressUnspentOutputsResponse) {}
	
	// **Requires TxIndex***
	// Returns a merkle (SPV) proof that the given transaction is in the provided block
	rpc GetMerkleProof(GetMerkleProofRequest) returns (GetMerkleProofResponse) {}
	
	// Submit a transaction to all connected peers.
	rpc SubmitTransaction(SubmitTransactionRequest) returns (SubmitTransactionResponse) {}
	
	// Subscribe to relevant transactions based on the subscription requests.
	// The parameters to filter transactions on can be updated by sending new
	// SubscribeTransactionsRequest objects on the stream.
	rpc SubscribeTransactions(stream SubscribeTransactionsRequest) returns (stream TransactionNotification) {}
	
	// Subscribe to notifications of new blocks being connected to the blockchain
	// or blocks being disconnected.
	rpc SubscribeBlocks(SubscribeBlocksRequest) returns (stream BlockNotification) {}
	
}
```

### Wallet Operation
// TODO
