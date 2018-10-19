%%%
Title = "LBRY: A Decentralized Digital Content Marketplace"
area = "Internet"

[seriesInfo]
name = "Internet-Draft"
value = "draft-grintsvayg-00"
stream = "IETF"
status = "informational"

date = 2018-08-21T00:00:00Z

[[author]]
initials="A."
surname="Grintsvayg"
fullname="Alex Grintsvayg"
%%%



# LBRY: A Decentralized Digital Content Marketplace


A> Please excuse the unfinished state of this paper. It is being actively worked on. The content here is made available early because it contains useful information for developers. 

A> For more technical information about LBRY, visit [lbry.tech](https://lbry.tech).


## Introduction

LBRY is a protocol for accessing and publishing digital content in a global, decentralized marketplace. Clients can use LBRY to publish, host, find, download, and pay for content — books, movies, music, or anything else. Anyone can participate and no permission is required, nor can anyone be blocked from participating. The system is distributed, so no single entity has unilateral control, nor will the removal of any single entity prevent the system from functioning.

TODO:

- why is it significant
- whom does it help
- why is it different/better than what existed before



## Table of Contents
 
 <div id="toc">

<!--ts-->
* [Overview](#overview)
* [Conventions and Terminology](#conventions-and-terminology)
* [Blockchain](#blockchain)
   * [Claims](#claims)
      * [Claim Operations](#claim-operations)
      * [Claimtrie](#claimtrie)
      * [Claim Properties](#claim-properties)
         * [Accepted](#accepted)
         * [Abandoned](#abandoned)
         * [Active](#active)
         * [Controlling](#controlling)
      * [Normalization](#normalization)
   * [URLs](#urls)
      * [Components](#components)
      * [Design Notes](#design-notes)
   * [Transactions](#transactions)
      * [Operations and Opcodes](#operations-and-opcodes)
      * [Addresses](#addresses)
      * [Proof of Payment](#proof-of-payment)
   * [Consensus](#consensus)
      * [Block Timing](#block-timing)
      * [Difficulty Adjustment](#difficulty-adjustment)
      * [Block Hash Algorithm](#block-hash-algorithm)
      * [Block Rewards](#block-rewards)
* [Metadata](#metadata)
   * [Metadata Specification](#metadata-specification)
   * [Key Metadata Fields](#key-metadata-fields)
      * [Streams and Stream Hashes](#streams-and-stream-hashes)
      * [Fees and Fee Structure](#fees-and-fee-structure)
      * [More?](#more)
   * [Identities](#identities)
   * [Metadata Validation](#metadata-validation)
* [Data](#data)
   * [Encoding and Decoding](#encoding-and-decoding)
      * [Blobs](#blobs)
      * [Streams](#streams)
      * [How to Turn Files into Streams, and Vice Versa](#how-to-turn-files-into-streams-and-vice-versa)
   * [Download](#download)
      * [Distributed Hash Table](#distributed-hash-table)
      * [Blob Exchange Protocol](#blob-exchange-protocol)
      * [Blob Mirrors](#blob-mirrors)
   * [Announcing](#announcing)
      * [Reflector / BlobEx Upload](#reflector--blobex-upload)
      * [Blob Mirrors](#blob-mirrors-1)
   * [Data Markets](#data-markets)
* [Conclusion](#conclusion)
<!--te-->

</div>



## Overview

This document defines the LBRY protocol, its components, and how they fit together. At its core, LBRY consists of several discrete components that are used together in order to provide the end-to-end capabilities of the protocol. There are two distributed data stores (blockchain and DHT), a peer-to-peer protocol for exchanging data, and several specifications for data structure, transformation, and retrieval. 

This document assumes that the reader is familiar with Bitcoin and blockchain technology. It does not attempt to document the Bitcoin protocol or explain how it works. The [Bitcoin developer reference](https://bitcoin.org/en/developer-reference) is recommended for anyone wishing to understand the technical details.



## Conventions and Terminology

(Rather than this section, maybe we can use a syntax like brackets around keywords to inline key definitions?)

<dl>
  <dt>file</dt>
  <dd>A single piece of content published using LBRY.</dd>

  <dt>blob</dt>
  <dd>The unit of data transmission on the data network. A published file is split into many blobs.</dd>

  <dt>stream</dt>
  <dd>A set of blobs that can be reassembled into a file. Every stream has a descriptor blob and one or more content blobs.</dd>

  <dt>blob hash</dt>
  <dd>The output of a cryptographic hash function is applied to a blob. Hashes are used to uniquely identify blobs and to verify that the contents of the blob are correct. Unless otherwise specified, LBRY uses SHA384 as the hash function.</dd>

  <dt>metadata</dt>
  <dd>Information about the contents of a stream (e.g. creator, description, stream descriptor hash, etc). Metadata is stored in the blockchain.</dd>

  <dt>claim</dt>
  <dd>A single metadata entry in the blockchain.</dd>

  <dt>name</dt>
  <dd>A human-readable UTF8 string that is associated with a published claim.</dd>

  <dt>channel</dt>
  <dd>The unit of pseudonymous publisher identity. Claims may be part of a channel.</dd>

  <dt>URL</dt>
  <dd>A reference to a claim that specifies how to retrieve it.</dd>
</dl>


## Blockchain

The LBRY blockchain is a public, proof-of-work blockchain. It serves three key purposes: 

1. An index of the content available on the network 
2. A payment system and record of purchases for priced content
3. Trustful publisher identities (fixme: should this even be listed here?)

The LBRY blockchain is a fork of the [Bitcoin](https://bitcoin.org/bitcoin.pdf) blockchain, with substantial modifications. This document will not cover or specify any aspects of LBRY that are identical to Bitcoin, and will instead focus on the differences.


### Claims
 
A single metadata entry in the blockchain is called a `claim`. It records an item that was published to the network or a publisher's identity.

Every claim has a globally-unique `claimID`, an `amount` (how many credits were set aside to back the claim), and a `value`. The value may contain metadata about a piece of content, a publisher's public key, or other information. See the [Metadata](#metadata) section for more information about what may be stored in the value.

Every claim is associated with a `name`, which is a bytestring of 0-255 bytes. Every name must be a valid UTF8 string.

Here is an example claim:

```
{
  "claimId": "fa3d002b67c4ff439463fcc0d4c80758e38a0aed",
  "name": "lbry",
  "amount": 100000000,
  "value": "{\"ver\": \"0.0.3\", \"description\": \"What is LBRY? An introduction with Alex Tabarrok\",
            \"license\": \"LBRY inc\", \"title\": \"What is LBRY?\", \"author\": \"Samuel Bryan\",
            \"language\": \"en\", \"sources\": {\"lbry_sd_hash\":
            \"e1e324bce7437540fac6707fa142cca44d76fc4e8e65060139a88ff7cdb218b4540cb9cff8bb3d5e06157ae6b08e5cb5\"},
            \"content_type\": \"video/mp4\", \"nsfw\": false, \"thumbnail\":
            \"https://s3.amazonaws.com/files.lbry.io/logo.png\"}",
  "txid": "53ed05d9dfd728a94bedf952d67783bbe9da5d2ab436a84338bb53f0b85301b5",
  "n": 0,
  "height": 146117
}
```



#### Claim Operations

There are four claim operations: `create`, `support`, `update`, and `abandon`.

A `create` operation makes a new claim for a name, or submits a competing claim on an existing name. 

A `support` is a claim that adds to the credit total of an existing claim. A support does not have it’s own claim ID or data. Instead, it has the claim ID of the claim to which its amount will be added. 

An `update` changes the data or the amount stored in an existing claim or support. Updates do not change the claim ID, so an updated claim retains any supports attached to it. 

An `abandon` withdraws a claim or support, freeing the associated credits to be used for other purposes.


#### Claimtrie

The `claimtrie` is the data structure that LBRY uses to store claims and prove the correctness of name resolution. It is a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree) that maps names to claims. Claims are stored as leaf nodes in the tree. Names are stored as the path from the root node to the leaf node.

The hash of the root node  (the `root hash`) is stored in the header of each block in the blockchain. Nodes in the LBRY network use the root hash to efficiently and securely validate the state of the claimtrie.

Multiple claims can exist for the same name. They are all stored in the leaf node for that name, sorted in decreasing order by the total amount of credits backing each claim.

For more details on the specific claimtrie implementation, see [the source code](https://github.com/lbryio/lbrycrd/blob/master/src/claimtrie.cpp).


#### Claim Properties

A claim can have one or more the following properties at a given block:

##### Accepted

An accepted claim or support is simply one that has been entered into the blockchain. This happens when the transaction containing the claim is included in a block.

##### Abandoned

An abandoned claim or support is one that was withdrawn by its creator. It is no longer in contention to control a name. Spending the transaction that contains the claim will also cause the claim to become abandoned.

While data related to abandoned claims technically still resides in the blockchain, it is considered inappropriate to use this data to fetch the associated content.

##### Active

A claim is active when it is in contention for controlling a name (or a support for such a claim). An active claim must be accepted and not abandoned. The time it takes an accepted claim to become active is called the activation delay, and it depends on the claim type, the height of the current block, and the height at which the last takeover occurred for the claim’s name.

If the claim is an update or support to the current controlling claim, or if it is the first claim for a name (T = 0), the claim becomes active as soon as it is accepted. Otherwise it becomes active at height A, where `A = C + D`, and `D = min(4032, floor((H-T) / 32))`.

- A = activation height
- D = activation delay
- C = claim height (height when the claim was accepted)
- H = current height
- T = takeover height (the most recent height at which the controlling claim for the name changed)

In plain English, the delay before a claim becomes active is equal to the claim’s height minus height of the last takeover, divided by 32. The delay is capped at 4032 blocks, which is 7 days of blocks at 2.5 minutes per block (our target block time). The max delay is reached 224 (7x32) days after the last takeover. The goal of this delay function is to give long-standing claimants time to respond to takeover attempts, while still keeping takeover times reasonable and allowing recent or contentious claims to be taken over quickly.

##### Controlling

The controlling claim is the claim that has the highest total effective amount, which is the sum of its own amount and the amounts of all of its supports. It must be active and cannot itself be a support.

Only one claim can be controlling for a given name at a given block. To determine which claim is controlling for a given name at a given block, the following algorithm is used:

1. For each active claim for the name, add up the amount of the claim and the amount of all the active supports for that claim. 

1. Determine if a takeover is happening

  1. If the claim with the greatest total is the controlling claim from the previous block, then nothing changes. That claim is still controlling at this block.

  1. Otherwise, a takeover is occurring. Set the takeover height for this name to the current height, recalculate which claims and supports are now active, and then perform step 1 again.

1. At this point, the claim with the greatest total is the controlling claim at this block.

The purpose of 2b is to handle the case when multiple competing claims are made on the same name in different blocks, and one of those claims becomes active but another still-inactive claim has the greatest amount. Step 2b will cause the greater claim to also activate and become the controlling claim.

Here is a step-by-step example to illustrate the different scenarios. All claims are for the same name.

**Block 13:** Claim A for 10LBC  is accepted. It is the first claim, so it immediately becomes active and controlling.
<br>State: A(10) is controlling

**Block 1001:** Claim B for 20LBC is accepted. It’s activation height is `1001 + min(4032, floor((1001-13) / 32)) = 1001 + 30 = 1031`.
<br>State: A(10) is controlling, B(20) is accepted.

**Block 1010:** Support X for 14LBC for claim A is accepted. Since it is a support for the controlling  claim, it activates immediately.
<br>State: A(10+14) is controlling, B(20) is accepted.

**Block 1020:** Claim C for 50LBC is accepted. The activation height is `1020 + min(4032, floor((1020-13) / 32)) = 1020 + 31 = 1051`.
<br>State: A(10+14) is controlling, B(20) is accepted, C(50) is accepted.

**Block 1031:** Claim B activates. It has 20LBC, while claim A has 24LBC (10 original + 14 from support X). There is no takeover, and claim A remains controlling.
<br>State: A(10+14) is controlling, B(20) is active, C(50) is accepted.

**Block 1040:** Claim D for 300LBC is accepted. The activation height is `1040 + min(4032, floor((1040-13) / 32)) = 1040 + 32 = 1072`.
<br>State: A(10+14) is controlling, B(20) is active, C(50) is accepted, D(300) is accepted.

**Block 1051:** Claim C activates. It has 50LBC, while claim A has 24LBC, so a takeover is initiated. The takeover height for this name is set to 1051, and therefore the activation delay for all the claims becomes `min(4032, floor((1051-1051) / 32)) = 0`. All the claims become active. The totals for each claim are recalculated, and claim D becomes controlling because it has the highest total.
<br>State: A(10+14) is active, B(20) is active, C(50) is active, D(300) is controlling.



#### Normalization

TODO: Talk about how claim names are normalized.

https://github.com/lbryio/lbrycrd/issues/208


### URLs

URLs are human-readable references to claims. All URLs contain a name, and can be resolved to a specific claim for that name. The ultimate purpose of much of the claim design, including controlling claims and the claimtrie structure, is to provide human-readable URLs that can be trustfully resolved by clients that have don't have a full copy of the blockchain.


#### Components

A URL is a name with one or more modifiers. A bare name on its own will resolve to the controlling claim at the latest block height, for reasons covered in [Design Notes](#design-notes). Common URL structures are:

**Name:** a basic claim for a name

```
lbry:meet-LBRY
```

**Claim ID:** a claim for this name with this claim ID (does not have to be the controlling claim). Partial prefix matches are allowed.

```
lbry:meet-LBRY#7a0aa95c5023c21c098
lbry:meet-LBRY#7a
```

**Claim Sequence:** the Nth claim for this name, in the order the claims entered the blockchain. N must be a positive number. This can be used to determine which claim came first, rather than which claim has the most support.

```
lbry:meet-LBRY:1
```

**Bid Position:** the Nth claim for this name, in order of most support to least support. N must be a positive number. This is useful for resolving non-winning bids in bid order, e.g. if you want to list the top three winning claims in a voting contest or want to ignore the activation delay.

```
lbry:meet-LBRY$2
lbry:meet-LBRY$3
```

**Query Params:** extra parameters (reserved for future use)

```
lbry:meet-LBRY?arg=value+arg2=value2
```

**Channel:** a claim for a channel

```
lbry:@lbry
```

**Claim in Channel:** URLS with a channel and a claim name are resolved in two steps. First the channel is resolved to get the claim for that channel. Then the name is resolved to get the appropriate claim from among the claims in the channel.

```
lbry:@lbry/meet-LBRY
```


The full URL grammar is defined below using [Xquery EBNF notation](https://www.w3.org/TR/2017/REC-xquery-31-20170321/#EBNFNotation):

<!-- see http://bottlecaps.de/rr/ui for visuals-->

```
URL ::= Scheme Path Query?

Scheme ::= 'lbry:'

Path ::=  ClaimNameAndModifier | ChannelAndModifier ( '/' ClaimNameAndModifier )?

ClaimNameAndModifier ::= ClaimName Modifier?
ChannelAndModifier ::= Channel Modifier?

ClaimName ::= AllowedChar+
Channel ::= '@' ClaimName

Modifier ::= ClaimID | ClaimSequence | BidPosition
ClaimID ::= '#' Hex+
ClaimSequence ::= ':' PositiveNumber
BidPosition ::= '$' PositiveNumber

Query ::= '?' QueryParameterList
QueryParameterList ::= QueryParameter ( '&' QueryParameterList )*
QueryParameter ::= QueryParameterName ( '=' QueryParameterValue )?
QueryParameterName ::= AllowedChar+
QueryParameterValue ::= AllowedChar+

PositiveDigit ::= [123456789]
Digit ::= '0' | PositiveDigit
PositiveNumber ::= PositiveDigit Digit*

HexAlpha ::= [abcdef]
Hex ::= (Digit | HexAlpha)+

AllowedChar ::= [^=&#:$@?/]  /* any UTF8 character that is not reserved */
```


#### Design Notes

Most existing public name schemes are first-come, first-serve. This leads to several bad outcomes. When the system is young, users are incentivized to register common names even if they don't intend to use them, in hopes of selling them to the proper owner in the future for an exorbitant price. In a centralized system, the authority may allow for appeals to reassign names based on trademark or other common use reasons. There may also be a process to "verify" that a name belongs to the entity you think it does (e.g. Twitter's verified accounts). Such processes are often arbitrary, change over time, involve significant transaction costs, and may still lead to names being used in ways that are contrary to user expectation (e.g. [nissan.com](http://nissan.com) is not what you’d expect).

In a decentralized system, such approaches are not possible, so name squatting is especially dangerous (see Namecoin). Instead, LBRY creates an efficient allocation of names via a market. Following [Coase](https://en.wikipedia.org/wiki/Coase_theorem), we believe that if the rules for name ownership and exchange are clearly defined, transaction costs are low, and there is no information asymmetry, then control of URLs will flow to their highest-valued use.

Note that only vanity URLs (i.e. URLs without a ClaimID or or ClaimSequence modifier) have this property. Permanent URLs like `lbry://myclaimname#abc` exist and are available for the small cost of issuing a `create` claim transactions.



### Transactions

To support claims, the LBRY blockchain makes the following changes on top of Bitcoin.


#### Operations and Opcodes

To enable [claim operations](#claim-operations), three new opcodes were added to the blockchain scripting language: `OP_CLAIM_NAME`, `OP_SUPPORT_CLAIM`, and `OP_UPDATE_CLAIM` (in Bitcoin they are respectively `OP_NOP6`, `OP_NOP7`, and `OP_NOP8`). Each op code will push a zero on to the execution stack, and will trigger the claimtrie to perform calculations necessary for each operation. Below are the three supported transactions scripts using these opcodes.

```
OP_CLAIM_NAME <name> <value> OP_2DROP OP_DROP <pubKey>

OP_UPDATE_CLAIM <name> <claimId> <value> OP_2DROP OP_2DROP <pubKey>

OP_SUPPORT_CLAIM <name> <claimId> OP_2DROP OP_DROP <pubKey>
```

`<pubKey>` can be any valid Bitcoin payout script, so a claimtrie script is also a pay-to-pubkey script to a user-controlled address. Note that the zeros pushed onto the stack by the claimtrie opcodes and vectors are all dropped by `OP_2DROP` and `OP_DROP`. This means that claimtrie transactions exist as prefixes to Bitcoin payout scripts and can be spent just like standard transactions.

For example, a claim transaction setting the name “Fruit” to “Apple” and using a pay-to-pubkey script will have the following payout script:

```
OP_CLAIM_NAME Fruit Apple OP_2DROP OP_DROP OP_DUP OP_HASH160 <addressOne> OP_EQUALVERIFY OP_CHECKSIG
```

Like any standard Bitcoin transaction output script, it will be associated with a transaction hash and output index. The transaction hash and output index are concatenated and hashed to create the claimID for this claim. For the example above, let's say the above transaction hash is `7560111513bea7ec38e2ce58a58c1880726b1515497515fd3f470d827669ed43` and the output index is `1`. Then the claimID would be `529357c3422c6046d3fec76be2358004ba22e323`.

A support for this bid will have the following payout script:

```
OP_SUPPORT_CLAIM Fruit 529357c3422c6046d3fec76be2358004ba22e323 OP_2DROP OP_DROP OP_DUP OP_HASH160 <addressTwo> OP_EQUALVERIFY OP_CHECKSIG
```

And now let's say we want to update the original claim to change the value to “Banana”. An update transaction has a special requirement that it must spend the existing claim that it wishes to update in its redeem script. Otherwise, it will be considered invalid and will not make it into the claimtrie. Thus it will have the following redeem script:

```
<signature> <pubKeyForAddressOne>
```

This is identical to the standard way of redeeming a pay-to-pubkey script in Bitcoin.

The payout script for the update transaction is:

```
OP_UPDATE_CLAIM Fruit 529357c3422c6046d3fec76be2358004ba22e323 Banana OP_2DROP OP_2DROP OP_DUP OP_HASH160 <addressThree> OP_EQUALVERIFY OP_CHECKSIG
```


#### Addresses

The address version byte is set to `0x55` for standard (pay-to-public-key-hash) addresses and `0x7a` for multisig (pay-to-script-hash) addresses. P2PKH addresses start with the letter `b`, and P2SH addresses start with `r`.

All the chain parameters are defined [here](https://github.com/lbryio/lbrycrd/blob/master/src/chainparams.cpp).

#### Proof of Payment

TODO: Explain how transactions serve as proof that a client has made a valid payment for a piece of content.


### Consensus

LBRY makes a few small changes to consensus rules.


#### Block Timing 

The target block time was lowered from 10 minutes to 2.5 minutes to facilitate faster transaction confirmation.

#### Difficulty Adjustment

The proof-of-work target is adjusted every block to better adapt to sudden changes in hash rate. The exact adjustment algorithm can be seen [here](https://github.com/lbryio/lbrycrd/blob/master/src/lbry.cpp).

#### Block Hash Algorithm

LBRY uses a combination of SHA256, SHA512, and RIPEMD160. The exact hashing algorithm can be seen [here](https://github.com/lbryio/lbrycrd/blob/master/src/hash.cpp#L18).

#### Block Rewards

The block reward schedule was adjusted to provide an initial testing period, a quick ramp-up to max block rewards, then a logarithmic decay to 0. The source for the algorithm is [here](https://github.com/lbryio/lbrycrd/blob/master/src/main.cpp#L1594).



## Metadata

Claim metadata is stored in a serialized format using [Protocol Buffers](https://developers.google.com/protocol-buffers/). This was chosen for several reasons:

- **Extensibility**. The metadata structure could grow to encompass thousands of fields for dozens of types of content. It should be easy to modify the structure while maintaining backward compatibility. Blockchain data is permanent and cannot be migrated.
- **Compactness**. Blockchain space is expensive. Data should be stored as compactly as possible.
- **Interoperability**. These definitions will be used by many projects written in different languages. Protocol buffers are language-independent and have great support for most popular languages.

No enforcement or validation on metadata happens at the blockchain level. Instead, metadata encoding, decoding, and validation is done by clients. This allows evolution of the metadata without changes to consensus rules.


### Metadata Specification

A useful index of available content must be succinct yet meaningful. It should be machine-readable, comprehensive, and should ideally point you toward the content you’re looking for. LBRY achieves this by defining a set of common properties for streams.

The metadata contains structured information describing the content, such as the title, author, language, and so on.

Here’s an example:

```
"metadata": {
  "author": "",
  "description": "All proceeds go to holly for buying toys, i will post the video with those toys on Xmas day",
  "language": "en",
  "license": "All rights reserved.",
  "licenseUrl": "",
  "nsfw": false,
  "preview": "",
  "thumbnail": "http://www.thetoydiscounter.com/happy.jpg",
  "title": "Holly singing The Happy Working Song",
  "source": {
    "contentType": "video/mp4",
    "source": "92b8aae7a901c56901fd5602c1f1acc0e63fb5492ef2a3cd5b9c631d92cab2e060e2a908baa922c24dee6c5229a98136",
    "sourceType": "lbry_sd_hash",
    "version": "_0_0_1"
  },
  "version": "_0_1_0"
}
```

Because the metadata structure can and does change frequently, a complete specification is omitted from this document. Instead, [github.com/lbryio/types](https://github.com/lbryio/types) should be consulted for the precise definition of current metadata structure.


### Key Metadata Fields

Despite not covering the full metadata structure, a few important metadata fields are highlighted below.

#### Streams and Stream Hashes

(The metadata property `sd_hash` contains a unique identifier to locate and find the content in the data network. Reference [[Data]].)

#### Fees and Fee Structure

- LBC
- Currencies?

#### More?



### Identities

Channels are the unit of identity in the LBRY system. A channel is a claim that start with `@` and contains a metadata structure for identities rather than content. The most important part of channel's metadata is the public key. Claims belonging to a channel are signed with the corresponding private key. A valid signature proves channel membership.

The purpose of channels is to allow content to be clustered under a single pseudonym or identity. This allows publishers to easily list all their content, maintain attribution, and build their brand.

Here’s the value of an example channel claim:

```
"certificate": {
    "keyType": "SECP256k1",
    "publicKey": "3056301006072a8648ce3d020106052b8104000a0342
                  0004180488ffcb3d1825af538b0b952f0eba6933faa6
                  d8229609ac0aeadfdbcf49C59363aa5d77ff2b7ff06c
                  ddc07116b335a4a0849b1b524a4a69d908d69f1bcebb",
    "version": "_0_0_1"
}
```

When a claim published into a channel, the claim data is signed and the following is added to the claim:

```
"publisherSignature": {
    "channelClaimID": "2996b9a087c18456402b57cba6085b2a8fcc136d", 
    "signature": "bf82d53143155bb0cac1fd3d917c000322244b5aD17
                  e7865124db2ed33812ea66c9b0c3f390a65a9E2d452
                  e315e91ae695642847d88e90348ef3c1fa283a36a8", 
    "signatureType": "SECP256k1", 
    "version": "_0_0_1"
}
```



### Metadata Validation

(expand)

- Validation 101
- Channel / identity validation



## Data

(This portion covers how content is actually encoded and decoded, fetched, and announced. Expand/fix.)

### Encoding and Decoding

#### Blobs

The unit of content in our network is called a `blob`. A blob is an encrypted chunk of data up to 2MB in size. Each blob is indexed by its `blob hash`, which is a SHA384 hash of the blob contents. Addressing blobs by their hashes simultaneously protects against naming collisions and ensures that the content you get is what you expect.

#### Streams

Multiple blobs may be combined into a `stream`. A stream may be a book, a movie, a CAD file, etc. All content on the network is shared as streams. Every stream begins with the `stream descriptor` blob, which contains a JSON list of the hashes and keys of the `content blobs`. The content blobs hold the actual content of the stream. Every stream ends with an empty content blob, to signify that the stream has finished (this is similar to a null-terminated string, and is necessary to support streaming content).

#### How to Turn Files into Streams, and Vice Versa

### Download

Data can be downloaded via one of two methods: the distributed data network and from centralized blob providers.

#### Distributed Hash Table

Distributed hash tables have proven to be an effective way to build a decentralized content network. Our DHT implementation follows the [Kademlia](https://pdos.csail.mit.edu/~petar/papers/maymounkov-kademlia-lncs.pdf)
spec fairly closely, with some modifications.

A distributed hash table is a key-value store that is spread over multiple host nodes in a network. Nodes may join or leave the network anytime, with no central coordination necessary. Nodes communicate with each other using a peer-to-peer protocol to advertise what data they have and what they are best positioned to store.

When a host connects to the DHT, it advertises the blob hash for every blob it wishes to share. Downloading a blob from the network requires querying the DHT for a list of hosts that advertised that blob’s hash (called peers), then requesting the blob from the peers directly.

#### Blob Exchange Protocol


#### Blob Mirrors

(fill me in)

### Announcing

(how stuff gets created / published)

#### Reflector / BlobEx Upload

#### Blob Mirrors

(Blob mirrors can also help you announce your content.)

### Data Markets

(Price negotiation.)

<!--

### Data Market

Hosts in the DHT can treat blobs as opaque chunks of data. There is price negotiation mechanism for data. So some hosts can be
purely interested in storing data and selling it. They may create algorithms for what data is more in demand (e.g. the first content
blob in a stream is probably requested more often than the last blob).

Talk about reputation system for hosts.

Talk about how lightning can be used for streaming payments.

-->

## Conclusion

*TODO*


<!---

### Supports, Tips

Supports add weight to name claims. They are kind of like voting. You retain control of the credits.
Tips are supports where person you tip gains control of the credits.

### Discovery

### Search

Search will be handled primarily by external indexing services. There are many existing search solutions
that would ingest the blockchain data and build an index of the content. The novel aspect of our system is
that the credits committed to a claim are a strong signal of relevance.

### Tagging

Tags provide extra information for content discovery. A tag has a claim ID and a name. Tags can be created,
supported, updated, and abandoned, just like claims. One key difference is that tag supports may be
labeled “negative” supports. A negative support reduces the effective amount of credits attached to a
tag. This is a signal that the tag is not a good fit for the content of the claim.

## Trust and Security

We believe that the

## Combatting the Ugly

Use this section to rebut some of the most common concerns regarding the nature of LBRY.

One of our core beliefs is that people want to pay the legitimate content owners and creators, as
long as the content reasonably-priced and the payment process is convenient.


Conclusion

Summary


-->

