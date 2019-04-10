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

// bchrpc contains a set of RPCs that can be exposed publically via
// the command line options. The idea is this service would be separate
// from the main service so that applications can connect to it without
// gaining access to the other RPCs which control node operation. This
// service could be authenticated or unauthenticated.
service bchrpc {
	
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
	
	// This RPC sends a block locator object to the server and the server responds with
	// a batch of no more than 2000 headers. Upon parsing the block locator, if the server
	// concludes there has been a fork, it will send headers starting at the fork point, 
	// or genesis if no blocks in the locator are in the best chain. If the locator is 
	// already at the tip no headers will be returned.
	rpc GetHeaders(GetHeadersRequest) return (GetHeadersResponse) {}
	
	// **Requires TxIndex**
	// Get a transaction given its hash.
	rpc GetTransaction(GetTransactionRequest) returns (GetTransactionResponse) {}
	
	// **Requires TxIndex**
	// Get a serialized transaction given its hash.
	rpc GetRawTransaction(GetRawTransactionRequest) returns (GetRawTransactionResponse) {}
	
	// **Requires AddressIndex**
	// Returns the transactions for the given address. Offers offset,
	// limit, and from block options.
	rpc GetAddressTransactions(GetAddressTransactionsRequest) returns (GetAddressTransactionsResponse) {}
	
	// **Requires AddressIndex**
	// Returns the raw transactions for the given address. Offers offset,
	// limit, and from block options.
	rpc GetRawAddressTransactions(GetRawAddressTransactionsRequest) returns (GetRawAddressTransactionsResponse) {}
	
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


// RPC MESSAGES

message GetMempoolInfoRequest {}
message GetRawBlockResponse {
	uint32 size = 1;
	uint32 bytes = 2;
}

message GetBlockchainInfoRequest {}
message GetBlockchainInfoResponse {
	enum BitcoinNet {
		MAINNET  = 0;
		REGTEST  = 1;
		TESTNET3 = 2;g
		SIMNET   = 3;
	}

	BitcoinNet bitcoin_net = 1;
	int32 best_height = 2;
	bytes best_block_hash = 3;
	double difficulty = 4;
	uint64 hashrate = 5;
	int64 median_time = 6;
	bool tx_index = 7;
	bool addr_index =8;
}

message GetBlockInfoRequest {
	oneof hash_or_height {
		bytes hash = 1;
		int32 height = 2;
	}
}
message GetBlockInfoResponse {
	BlockInfo info = 1;
}

message GetBlockRequest {
	oneof hash_or_height {
		bytes hash = 1;
		int32 height = 2;
	}
	// Provide full transaction info instead of only the hashes.
	bool full_transactions = 3;
}
message GetBlockResponse {
	Block block = 1;
}

message GetRawBlockRequest {
	oneof hash_or_height {
		bytes hash = 1;
		int32 height = 2;
	}
}
message GetRawBlockResponse {
	bytes block = 1;
}

message GetHeadersRequest {
	repeated bytes block_locator_hashes = 1;
	bytes stop_hash = 2;
}
message GetHeadersResponse {
	repeated BlockInfo headers = 1;
}

message GetTransactionRequest {
	bytes hash = 1;
}
message GetTransactionResponse {
	Transaction transaction = 1;
}

message GetRawTransactionRequest {
	bytes hash = 1;
}
message GetRawTransactionResponse {
	bytes transaction = 1;
}

message GetAddressTransactionsRequest {
	string address = 1;

	// Control the number of transactions to be fetched from the blockchain.
	// These controls only apply to the confirmed transactions. All unconfirmed 
	// ones will be returned always.
	uint32 nb_skip = 2;
	uint32 nb_fetch = 3;
	
	// If the start block is provided it will only return transactions after this
	// block. This should be used if possible to save bandwidth. 
	oneof start_block {
		bytes hash = 1;
		int32 height = 2;
	}
}
message GetAddressTransactionsResponse {
	repeated Transaction confirmed_transactions = 1;
	repeated MempoolTransaction unconfirmed_transactions = 2;
}

message GetRawAddressTransactionsRequest {
	string address = 1;

	// Control the number of transactions to be fetched from the blockchain.
	// These controls only apply to the confirmed transactions. All unconfirmed 
	// ones will be returned always.
	uint32 nb_skip = 2;
	uint32 nb_fetch = 3;
	
	// If the start block is provided it will only return transactions after this
	// block. This should be used if possible to save bandwidth. 
	oneof start_block {
		bytes hash = 1;
		int32 height = 2;
	}
}
message GetRawAddressTransactionsResponse {
	repeated bytes confirmed_transactions = 1;
	repeated bytes unconfirmed_transactions = 2;
}

message GetAddressUnspentOutputsRequest {
	string address = 1;
}
message GetAddressUnspentOutputsResponse {
	repeated UnspentOutput outputs = 1;
}

message GetMerkleProofRequest {
	bytes transaction_hash = 1;
}
GetMerkleProofResponse {
	BlockInfo block = 1;
	repeated bytes hashes = 2;
	bytes flags = 3;
}

message SubmitTransactionRequest {
	bytes transaction = 1;
}
message SubmitTransactionResponse {
	bytes hash = 1;
}

message SubscribeTransactionsRequest {
	TransactionFilter subscribe = 1;
	TransactionFilter unsubscribe = 2;

	// When this is true, also new transactions coming in from the mempool are 
	// included apart from the ones confirmed in a block.  These transactions
	// will be sent again when they are confirmed.
	bool include_mempool = 3;
}

message SubscribeBlocksRequest {}


// NOTIFICATIONS

message BlockNotification {
	enum Type {
		CONNECTED = 0;
		DISCONNECTED = 1;
	}

	Type type = 1;
	BlockInfo block = 2;
}

message TransactionNotification {
	enum Type {
		UNCONFIRMED = 0;
		CONFIRMED   = 1;
	}

	Type type = 1;
	oneof transaction {
		Transaction confirmed_transaction = 2;
		MempoolTransaction accepted_transaction = 3;
	}
}


// DATA MESSAGES

message BlockInfo {
	// Identification.
	bytes hash = 1;
	int32 height = 2;

	// Block header data.
	int32 version = 3;
	bytes previous_block = 4;
	bytes merkle_root = 5;
	int64 timestamp = 6;
	uint32 bits = 7;
	uint32 nonce = 8;

	// Metadata.
	int32 confirmations = 9;
	double difficulty = 10;
	bytes next_block_hash = 11;
}

message Block {
	BlockInfo info = 1;
	
	// Either one of the two following is provided, depending on the request.
	oneof txids_or_txs {
		repeated bytes transaction_hashes = 2;
		repeated Transaction transactions = 3;
	}
}

message Transaction {
	message Input {
		message Outpoint {
			bytes hash = 1;
			uint32 index = 2;
		}

		bool coinbase = 1;
		Outpoint outpoint = 2;
		bytes signature_script = 3;
		uint32 sequence = 4;
		
		// TODO: This might not be available. Double check.
		int64 value = 5;
	}
	message Output {
		uint32 index = 1;
		int64 value = 2;
		bytes pubkey_script = 3;
		
		//TODO: Are these extra script values relevant?
		// - address
		// - disassembled script
		// - script class
	}

	bytes hash = 1;
	int32 version = 2;
	repeated Input inputs = 3;
	repeated Output outputs = 4;
	uint32 lock_time = 5;

	// Metadata
	int32 size = 8;
	int64 timestamp = 9;
	int32 confirmations = 10;
	int32 block_height = 11;
	bytes block_hash = 12;
}

message MempoolTransaction {
	Transaction transaction = 1;

	// The time when the transaction was added too the pool.
	int64 added_time = 2;
	// The block height when the transaction was added to the pool.
	int32 added_height = 3;
	// The total fee in satoshi the transaction pays.
	int64 fee = 4;
	// The fee in satoshi per byte the transaction pays.
	int64 fee_per_byte = 5;
	// The priority of the transaction when it was added to the pool.
	double starting_priority = 6;
}

message UnspentOutput {
	Transaction.Input.Outpoint outpoint = 1;
	bytes pubkey_script = 2;
	int64 value = 3;

	bool is_coinbase = 4;
	int32 block_height = 5;
}

message TransactionFilter {
	repeated string addresses = 1;
	repeated Transaction.Input.Outpoint outpoints = 2;
	
	//TODO: Are these extra filters values relevant?
	// - scriptPubkey
	// - script data elements
	
	// Subscribed/Unsubscribe to everything. Other filters
	// will be ignored.
	bool all_transactions = 3;
}

```

### Wallet Operation
// TODO
