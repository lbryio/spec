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
      * [Claim Properties](#claim-properties)
      * [Claim Example](#claim-example)
      * [Claim Operations](#claim-operations)
      * [Supports](#supports)
      * [Claimtrie](#claimtrie)
      * [Claim and Support Statuses](#claim-and-support-statuses)
         * [Accepted](#accepted)
         * [Abandoned](#abandoned)
         * [Active](#active)
         * [Controlling](#controlling)
      * [Claimtrie Transitions](#claimtrie-transitions)
         * [Determining Active Claims](#determining-active-claims)
            * [Claim Transition Example](#claim-transition-example)
      * [Normalization](#normalization)
   * [URLs](#urls)
      * [Components](#components)
      * [Grammar](#grammar)
      * [Resolution](#resolution)
         * [No Modifier](#no-modifier)
         * [ClaimID](#claimid)
         * [ClaimSequence](#claimsequence)
         * [BidPosition](#bidposition)
         * [ChannelName and ClaimName](#channelname-and-claimname)
         * [Examples](#examples)
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
   * [Identities](#identities)
   * [Metadata Validation](#metadata-validation)
* [Data](#data)
   * [Encoding and Decoding](#encoding-and-decoding)
      * [Blobs](#blobs)
      * [Streams](#streams)
      * [Manifest Contents](#manifest-contents)
      * [Stream Encoding](#stream-encoding)
         * [Setup](#setup)
         * [Content Blobs](#content-blobs)
         * [Manifest Blob](#manifest-blob)
      * [Stream Decoding](#stream-decoding)
   * [Announce](#announce)
      * [Distributed Hash Table](#distributed-hash-table)
      * [Announcing to the DHT](#announcing-to-the-dht)
   * [Download](#download)
      * [Querying the DHT](#querying-the-dht)
      * [Blob Exchange Protocol](#blob-exchange-protocol)
         * [PriceCheck](#pricecheck)
         * [DownloadCheck](#downloadcheck)
         * [Download](#download-1)
         * [UploadCheck](#uploadcheck)
         * [Upload](#upload)
   * [Reflectors and Data Markets](#reflectors-and-data-markets)
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

<!-- done -->

The LBRY blockchain is a public, proof-of-work blockchain. It serves three key purposes: 

1. An index of the content available on the network 
2. A payment system and record of purchases for priced content
3. Trustful publisher identities

The LBRY blockchain is a fork of the [Bitcoin](https://bitcoin.org/bitcoin.pdf) blockchain, with substantial modifications. This document will not cover or specify any aspects of LBRY that are identical to Bitcoin, and will instead focus on the differences.

### Claims

<!-- done -->

A _claim_ is a single metadata entry in the blockchain. There are two types of claims:

<dl>
  <dt>stream</dt>
  <dd>Declares the availability, access method, and publisher of a stream of bytes (typically a file).</dd>
  <dt>channel</dt>
  <dd>Creates a trustful pseudonym that can be used to identify the origin of stream claims.</dd>
</dl>

#### Claim Properties

Claims have 4 properties:

<dl>
  <dt>claimId</dt>
  <dd>A 20-byte hash unique among all claims. See [Claim Identifier Generation](#claim-identifier-generation).</dd>
  <dt>name</dt>
  <dd>A normalized UTF-8 string of up to 255 bytes used to address the claim. See [URLs](#urls) and [Normalization](#normalization).</dd>
  <dt>amount</dt>
  <dd>A quantity of tokens used to stake the claim. See [Controlling](#controlling).</dd>
  <dt>value</dt>
  <dd>Metadata about a stream or a channel. See [Metadata](#metadata).</dd>
</dl>
  
#### Claim Example

<!-- done -->

Here is an example stream claim:

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

<!-- done -->

There are three claim operations: _create_, _update_, and _abandon_.

<dl>
  <dt>create</dt>
  <dd>Makes a new claim.</dd>
  <dt>update</dt>
  <dd>Changes the value or amount of an existing claim, without changing the claim ID.</dd>
  <dt>abandon</dt>
  <dd>Withdraws a claim, freeing the associated credits to be used for other purposes.</dd>
</dl>

#### Supports

A _support_ is an additional transaction type that lends its _amount_ to an existing claim.

A support contains a claim ID, and amount, and nothing else. Supports function analogously to claims in terms of [Claim Operations](#claim-operations) and [Claim Statuses](#claim-statuses), with the exception that they cannot be updated.

#### Claimtrie

<!-- done -->

The _claimtrie_ is the data structure used to store the set of all claims and prove the correctness of claim resolution. 

The claimtrie is implemented as a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree) that maps names to claims. Claims are stored as leaf nodes in the tree. Names are stored as the path from the root node to the leaf node.

The _root hash_ is the hash of the root node. It is stored in the header of each block in the blockchain. Nodes in the LBRY network use the root hash to efficiently and securely validate the state of the claimtrie.

Multiple claims can exist for the same name. They are all stored in the leaf node for that name, sorted in decreasing order by the total amount of credits backing each claim.

For more details on the specific claimtrie implementation, see [the source code](https://github.com/lbryio/lbrycrd/blob/master/src/claimtrie.cpp).

#### Claim and Support Statuses

<!-- fix me? is using claims to mean claims and supports okay? -->

All claims and supports can have one or more the following statuses at a given block.

Throughout this section, whenever we write claim, we refer to both claims and supports.

##### Accepted

<!-- done -->

An _accepted_ claim is one that has been been entered into the blockchain. This happens when the transaction containing it is included in a block.

Accepted claims do not appear in or affect the claimtrie state until they are [Active](#active).

The sum of the amount of a claim and all accepted supports is called the _total amount_.

##### Abandoned

<!-- done -->

An _abandoned_ claim is one that was withdrawn by its creator or current owner. Spending a transaction that contains a claim will cause that claim to become abandoned.

Abandoned claims are no longer stored in the claimtrie.

While data related to abandoned claims technically still resides in the blockchain, it is improper to use this data to fetch the associated content, and active claims signed by abandoned identities will no longer be reported as valid.

##### Active

<!-- fix me a lot -->

An _active_ claim is an accepted and non-abandoned claim that has been in the blockchain for an algorithmically determined number of blocks. This length of time required is called the _activation delay_.

If the claim is an update to an already active claim, is the first claim for a name, or does not affect the sort order at the leaf for a name, the activation delay is 0 (i.e. the claim becomes active in the same block it is accepted). 

Otherwise, the activation delay is determined by a formula covered in [Claimtrie Transitions](#claimtrie-transitions). The formula's variable inputs are the height of the current block, the height at which the claim was accepted, and the height at which the relevant claimtrie state for the name being considered last changed.

The sum of the amount of an active claim and all active supports is called it's _effective amount_. Only the effective amount affects the sort order of a claimtrie leaf.

##### Controlling

<!-- done -->

A _controlling_ claim is the active claim that is first in the sort order at a leaf. That is, it has the highest total effective amount of all claims with the same name. 

Only one claim can be controlling for a given name at a given block. 

#### Claimtrie Transitions

<!-- fix me -->

To determine the sort order of a claimtrie leaf, the following algorithm is used:

1. For each active claim for the name, add up the amount of the claim and the amount of all the active supports for that claim. 

1. If all of the claims for a name are in the same order (appending new claims allowed), then nothing is changing.

1. Otherwise, a takeover is occurring. Set the takeover height for this name to the current height, recalculate which claims and supports are now active, and return to step 1.

1. At this point, the claim with the greatest total is the controlling claim at this block.

The purpose of 3 is to handle the case when multiple competing claims are made on the same name in different blocks, and one of those claims becomes active but another still-inactive claim has the greatest amount. Step 3 will cause the greater claim to also activate and become the controlling claim.

##### Determining Active Claims

If a claim does not become active immediately, it becomes active at the block heigh determined by the following formula:

```
C + min(4032, floor((H-T) / 32))
```

Where: 

- C = claim height (height when the claim was accepted)
- H = current height
- T = takeover height (the most recent height at which the relevant claimtrie state for the name changed)

In written form, the delay before a claim becomes active is equal to the claim’s height minus height of the last takeover, divided by 32. The delay is capped at 4032 blocks, which is 7 days of blocks at 2.5 minutes per block (our target block time). The max delay is reached 224 (7x32) days after the last takeover. 

The purpose of this delay function is to give long-standing claimants time to respond to changes, while still keeping takeover times reasonable and allowing recent or contentious claims to change state quickly.

###### Claim Transition Example

<!-- done -->

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

<!-- done -->

Names in the claimtrie are normalized to avoid confusion due to Unicode equivalence or casing. All names are converted using [Unicode Normalization Form D](http://unicode.org/reports/tr15/#Norm_Forms) (NFD), then lowercased using the en_US locale when possible. 

### URLs

<!-- fix me - @grin does SPV need a mention inside of the document? -->

URLs are human-readable references to claims. All URLs:

1. must contain a name (see [Claim Properties](#claim-properties))
2. and resolve to a single, specific claim for that name

The ultimate purpose of much of the claim and blockchain design is to provide human-readable URLs that can be trustfully resolved by clients that have don't have a full copy of the blockchain (i.e. [Simplified Payment Verification](https://lbry.tech/glossary#spv) wallets).


#### Components

<!-- done -->

A URL is a name with one or more modifiers. A bare name on its own will resolve to the [controlling claim](#controlling) at the latest block height. Common URL structures are:

**Stream Claim Name:** a basic claim for a name

```
lbry://meet-lbry
```

**Channel Claim Name:** a claim for a channel

```
lbry://@lbry
```

**Channel Claim Name and Stream Claim Name:** URLS with a channel and a stream claim name are resolved in two steps. First the channel is resolved to get the appropriate claim for that channel. Then the stream claim name is resolved to get the appropriate claim from among the claims in the channel.

```
lbry://@lbry/meet-lbry
```

**Claim ID:** a claim for this name with this claim ID (does not have to be the controlling claim). Partial prefix matches are allowed (see [Resolution](#resolution)).

```
lbry://meet-lbry#7a0aa95c5023c21c098
lbry://meet-lbry#7a
lbry://@lbry#3f/meet-lbry
```

**Claim Sequence:** the Nth claim for this name, in the order the claims entered the blockchain. N must be a positive number. This can be used to determine which claim came first, rather than which claim has the most support.

```
lbry://meet-lbry:1
lbry://@lbry:1/meet-lbry
```

**Bid Position:** the Nth claim for this name, in order of most support to least support. N must be a positive number. This is useful for resolving non-winning bids in bid order, e.g. if you want to list the top three winning claims in a voting contest or want to ignore the activation delay.

```
lbry://meet-lbry$2
lbry://meet-lbry$3
lbry://@lbry$2/meet-lbry
```

**Query Params:** extra parameters, reserved for future use

```
lbry://meet-lbry?arg=value+arg2=value2
```

#### Grammar

The full URL grammar is defined using [Xquery EBNF notation](https://www.w3.org/TR/2017/REC-xquery-31-20170321/#EBNFNotation):

<!-- see http://bottlecaps.de/rr/ui for visuals-->

```
URL ::= Scheme Path Query?

Scheme ::= 'lbry://'

Path ::=  StreamClaimNameAndModifier | ChannelClaimNameAndModifier ( '/' StreamClaimNameAndModifier )?

StreamClaimNameAndModifier ::= StreamClaimName Modifier?
ChannelClaimNameAndModifier ::= ChannelClaimName Modifier?

StreamClaimName ::= NameChar+
ChannelClaimName ::= '@' NameChar+

Modifier ::= ClaimID | ClaimSequence | BidPosition
ClaimID ::= '#' Hex+
ClaimSequence ::= ':' PositiveNumber
BidPosition ::= '$' PositiveNumber

Query ::= '?' QueryParameterList
QueryParameterList ::= QueryParameter ( '&' QueryParameterList )*
QueryParameter ::= QueryParameterName ( '=' QueryParameterValue )?
QueryParameterName ::= NameChar+
QueryParameterValue ::= NameChar+

PositiveDigit ::= [123456789]
Digit ::= '0' | PositiveDigit
PositiveNumber ::= PositiveDigit Digit*

HexAlpha ::= [abcdef]
Hex ::= (Digit | HexAlpha)+

NameChar ::= Char - [=&#:$@?/]  /* any character that is not reserved */
Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] /* any Unicode character, excluding the surrogate blocks, FFFE, and FFFF. */
```

#### Resolution

URL _resolution_ is the process of translating a URL into it's associated claim id and metadata. 

##### No Modifier

Return the controlling claim for the name. Stream claims and channel claims are resolved the same way.

##### ClaimID

Get all claims for the claim name whose IDs start with the given `ClaimID`. Sort the claims in ascending order by block height and position within the block. Return the first claim.

##### ClaimSequence

Get all claims for the claim name. Sort the claims in ascending order by block height and position within the block. Return the Nth claim, where N is the given `ClaimSequence` value.

##### BidPosition

Get all claims for the claim name. Sort the claims in descending order by total effective amount. Return the Nth claim, where N is the given `BidSequence` value.

##### ChannelName and ClaimName

<!-- fix me: explain how claim signing works, and what it means to be **in** a channel -->

If both a channel name and a claim name is present, resolution happens in two steps. First, remove the `/` and `StreamClaimNameAndModifier` from the path, and resolve the URL as if it only had a `ChannelClaimNameAndModifier`. Then get the list of all claims in that channel. Finally, resolve the `StreamClaimNameAndModifier` as if it was its own URL, but instead of considering all claims, only consider the set of claims in the channel.

Technically, if multiple claims for the same name exist inside the same channel, they are resolved via the same resolution rules applied entirely within the sub-scope of the channel. Pragmatically, it rarely makes sense for channels to use the same name twice and support for this functionality may be unreliable in current tooling.

##### Examples

Suppose the following names were claimed in the following order:


Name            | Claim ID  | Amount
:---            | :---      | :---
apple           | 690eea    | 1
banana          | 714a3f    | 2
cherry          | bfaabb    | 100
apple           | 690eea    | 10
@Arthur         | b7bab5    | 1
@Bryan          | 0da517    | 1
@Chris          | b3f7b1    | 1
@Chris/banana   | fc861c    | 1
@Arthur/apple   | 37ee1     | 20
@Bryan/cherry   | a18bca    | 10
@Chris          | 005a7d    | 100
@Arthur/cherry  | d39aa0    | 20

Here is how the following URLs should resolve:

URL                          | Claim ID     | Note
:---                         | :---         | :---
`lbry://apple`               | a37ee1 
`lbry://banana`              | 714a3f 
`lbry://@Chris`              | 005a7d 
`lbry://@Chris/banana`       | _not found_  | the controlling `@Chris` does not have a `banana`
`lbry://@Chris:1/banana`     | fc861c
`lbry://@Chris:#fc8/banana`  | fc861c
`lbry://cherry`              | bfaabb 
`lbry://@Arthur/cherry`      | d39aa0 
`lbry://@Bryan`              | 0da517 
`lbry://banana$1`            | 714a3f 
`lbry://banana$2`            | fc861c 
`lbry://banana$3`            | _not found_
`lbry://@Arthur:1`           |  b7bab5

#### Design Notes

The most contentious aspect of this design has been the choice to resolve naked names (sometimes called _vanity names_) to the claim with the largest number of staked credits.

First, it is important to note the problems in existing domain allocation design. Most existing public name schemes are first-come, first-serve with a fixed price. This leads to several bad outcomes:

1. Speculation and extortion. Entrepreneurs are incentivized to register common names even if they don't intend to use them, in hopes of selling them to the proper owner in the future for an exorbitant price. While speculation in general can have positive externalities, in this case it is pure value extraction. It also harms the user experience of users, who will see the vast majority of URLs sitting unused (c.f. Namecoin).

1. Bureaucracy and transaction costs. While a centralized system can allow for an authority to use a process to reassign names based on trademark or other common use reasons, this system is also imperfect. Most importantly, it is a censorship point and an avenue for complete exclusion. Additionally, such processes are often arbitrary, change over time, involve significant transaction costs, and _still_ lead to names being used in ways that are contrary to user expectation (e.g. [nissan.com](http://nissan.com)).

1. Inefficencies from price controls. Any system that does not allow a price to float completely freely creates inefficiencies. If the set price is too low, we facilitate speculation and rent-seeking. If the price is too high, we see people excluded from a good that it would otherwise be beneficial for them to purchase. 

Thus, we need an algorithmic design built into consensus that allows URLs to flow to their highest valued use. Following [Coase](https://en.wikipedia.org/wiki/Coase_theorem), this design allows for clearly defined rules, low transaction costs, and no information asymmetry, ensuring minimal inefficiency in URL allocation.

It's also important to note that _only_ vanity URLs have this property. Extremely short, memorable URLs like `lbry://myclaimname#a` exist and are available for the minimal cost of issuing a transaction.


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

(The metadata property `lbry_sd_hash` contains a unique identifier to locate and find the content in the data network. Reference [[Data]].)

#### Fees and Fee Structure

- LBC
- Currencies?
- channel signatures and private keys




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

Clients are responsible for validating metadata, including data structure and signatures. 

(expand)

- Validation 101
- ChannelName / identity validation



## Data

(This portion covers how content is actually encoded and decoded, fetched, and announced. Expand/fix.)



### Encoding and Decoding

<!-- done -->

Content on the LBRY network is encoded to facilitate distribution.

#### Blobs

<!-- done -->

The unit of data in the LBRY network is called a _blob_. A blob is an encrypted chunk of data up to 2MiB in size. Each blob is indexed by its _blob hash_, which is a SHA384 hash of the blob contents. Addressing blobs by their hash protects against naming collisions and ensures that the content you get is what you expect.

Blobs are encrypted using AES-256 in CBC mode and PKCS7 padding. In order to keep each encrypted blob at 2MiB max, a blob can hold at most 2097151 bytes (2MiB minus 1 byte) of plaintext data. The source code for the exact algorithm is available [here](https://github.com/lbryio/lbry.go/blob/master/stream/blob.go). The encryption key and IV for each blob is stored as described below. 

#### Streams

<!-- done -->

Multiple blobs are combined into a _stream_. A stream may be a book, a movie, a CAD file, etc. All content on the network is shared as streams. Every stream begins with the _manifest blob_, followed by one or more _content blobs_. The content blobs hold the actual content of the stream. The manifest blob contains information necessary to find the content blobs and decode them into a file. This includes the hashes of the content blobs, their order in the stream, and cryptographic material for decrypting them.

The blob hash of the manifest blob is called the _stream hash_. It uniquely identifies each stream.

#### Manifest Contents

<!-- done -->

A manifest blob's contents are encoded using a canonical JSON encoding. The JSON encoding must be canonical to support consistent hashing and validation. The encoding is the same as standard JSON, but adds the following rules:

- Object keys must be quoted and lexicographically sorted.
- All strings are hex-encoded. Hex letters must be lowercase.
- Whitespace before, after, or between tokens is not permitted.
- Floating point numbers, leading zeros, and "minus 0" for integers are not permitted.
- Trailing commas after the last item in an array or object are not permitted.

Here's an example manifest: 

<!-- originally from 053b2f0f0e82e7f022837382733d5f5817dcd67027103fe43f00fa7a6f9fa8742c1022a851616c1ac15d1c60e89db3f4 -->

```
{"blobs":[{"blob_hash":"a6daea71be2bb89fab29a2a10face08143411a5245edcaa5efff48c2e459e7ec01ad20edfde6da43a932aca45b2cec61","iv":"ef6caef207a207ca5b14c0282d25ce21","length":2097152},{"blob_hash":"bf2717e2c445052366d35bcd58edb108cbe947af122d8f76b4856db577aeeaa2def5b57dbb80f7b1531296bd3e0256fc","iv":"a37b291a37337fc1ff90ae655c244c1d","length":2097152},...,{"blob_hash":"322973617221ddfec6e53bff4b74b9c21c968cd32ba5a5094d84210e660c4b2ed0882b114a2392a08b06183f19330aaf","iv": "a00f5f458695bdc9d50d3dbbc7905abc","length":600160}],"filename":"6b706a7977755477704d632e6d7034","key":"94d89c0493c576057ac5f32eb0871180","version":1}
```

Here's the same manifest, with whitespace added for readability:

```
{
  "blobs":[
    {
      "blob_hash":"a6daea71be2bb89fab29a2a10face08143411a5245edcaa5efff48c2e459e7ec01ad20edfde6da43a932aca45b2cec61",
      "iv":"ef6caef207a207ca5b14c0282d25ce21",
      "length":2097152
    },
    {
      "blob_hash":"bf2717e2c445052366d35bcd58edb108cbe947af122d8f76b4856db577aeeaa2def5b57dbb80f7b1531296bd3e0256fc",
      "iv":"a37b291a37337fc1ff90ae655c244c1d",
      "length":2097152
    },
    ...,
    {
      "blob_hash":"322973617221ddfec6e53bff4b74b9c21c968cd32ba5a5094d84210e660c4b2ed0882b114a2392a08b06183f19330aaf",
      "iv": "a00f5f458695bdc9d50d3dbbc7905abc",
      "length": 600160
    }  
  ],
  "filename":"6b706a7977755477704d632e6d7034",
  "key":"94d89c0493c576057ac5f32eb0871180",
  "version":1
}
```

The `key` field contains the key to decrypt the stream, and is optional. The key may be stored by a third party and made available to a client when presented with proof that the content was purchased. The `version` field is always 1. It is intended to signal structure changes in future versions of this protocol. The `length` field for each blob is the length of the encrypted blob, not the original file chunk.

Every stream must have at least two blobs - the manifest blob and a content blob. Consequently, zero-length streams are not allowed.



#### Stream Encoding

<!-- done -->

A file must be encoded into a stream before it can be published. Encoding involves breaking the file into chunks, encrypting the chunks into content blobs, and creating the manifest blob. Here are the steps:

##### Setup

<!-- done -->

1. Generate a random 32-byte key for the stream.

##### Content Blobs

<!-- done -->

1. Break the file into chunks of at most 2097151 bytes.
1. Generate a random IV for each chuck.
1. Pad each chunk using PKCS7 padding
1. Encrypt each chunk with AES-CBC using the stream key and the IV for that chunk.
1. An encrypted chunk is a blob.

##### Manifest Blob

<!-- done -->

1. Fill in the manifest data.
1. Encode the data using the canonical JSON encoding described above.
1. Compute the stream hash.

An implementation of this process is available [here](https://github.com/lbryio/lbry.go/tree/master/stream).
fixme: this link is for v0, not v1. need to implement v1 or drop the link.


#### Stream Decoding

<!-- done -->

Decoding a stream is like encoding in reverse, and with the added step of verifying that the expected blob hashes match the actual data.

1. Verify that the manifest blob hash matches the stream hash you expect.
1. Parse the manifest blob contents.
1. Verify the hashes of the content blobs.
1. Decrypt and remove the padding from each content blob using the key and IVs in the manifest.
1. Concatenate the decrypted chunks in order.



### Announce

After a [[stream]] is encoded, it must be _announced_ to the network. Announcing is the process of letting other nodes on the network know that you have content available for download. The LBRY network tracks announced content using a distributed hash table.

#### Distributed Hash Table

_Distributed hash tables_ (or DHTs) have proven to be an effective way to build a decentralized content network. Our DHT implementation follows the [Kademlia](https://pdos.csail.mit.edu/~petar/papers/maymounkov-kademlia-lncs.pdf)
specification fairly closely, with some modifications.

A distributed hash table is a key-value store that is spread over multiple nodes in a network. Nodes may join or leave the network anytime, with no central coordination necessary. Nodes communicate with each other using a peer-to-peer protocol to advertise what data they have and what they are best positioned to store.

When a host connects to the DHT, it announces the hash for every [[blob]] it wishes to share. Downloading a blob from the network requires querying the DHT for a list of hosts that announced that blob’s hash (called _peers_), then requesting the blob from the peers directly.

#### Announcing to the DHT

A host announces a hash to the DHT in two steps. First, the host looks for nodes that are closest to the target hash. Then the host asks those nodes to store the fact that the host has the target hash available for download.

Finding the closest nodes is done via iterative `FindNode` DHT requests. The host starts with the closest nodes it knows about and sends a `FindNode(target_hash)` request to each of them. If any of the requests return nodes that are closer to the target hash, the host sends `FindNode` requests to those nodes to try to get even closer. When the `FindNode` requests no longer return nodes that are closer, the search ends.

Once the search is over, the host takes the 8 closest nodes it found and sends a `Store(target_hash)` request to them. The nodes receiving this request store the fact that the host is a peer for the target hash. 


### Download

A client wishing to download a [[stream]] must first query the [[DHT]] to find [[peers]] hosting the [[blobs]] in that stream, then contact those peers to download the blobs directly.

#### Querying the DHT

Querying works almost the same way as [[announcing]]. A client looking for a target hash will start by sending iterative `FindValue(target_hash)` requests to the nodes it knows that are closest to the target hash. If a node receives a `FindValue` request and knows of any peers for the target hash, it will respond with a list of those peers. Otherwise, it will respond with the closest nodes to the target hash that it knows about. The client then queries those closer nodes using the same `FindValue` call. This way, each call either finds the client some peers, or brings it closer to finding those peers. If no peers are found and no closer nodes are being returned, the client will determine that the target hash is not available and will give up.


#### Blob Exchange Protocol

Downloading a blob from a peer is governed by the _Blob Exchange Protocol_. It is used by hosts and clients to check blob availability, exchange blobs, and negotiate data prices. The protocol is an RPC protocol using Protocol Buffers and the gRPC framework. It has five types of requests.

fixme: protocol does not **negotiate** anything right now. It just checks the price. Should we include negotiation in v1?

##### PriceCheck

PriceCheck gets the price that the server is charging for data transfer. It returns the prices in [[deweys]] per KB.

##### DownloadCheck

DownloadCheck checks whether the server has certain blobs available for download. For each hash in the request, the server returns a true or false to indicate whether the blob is available.

##### Download

Download requests the blob for a given hash. The response contains the blob, its hash, and the address where to send payment for the data transfer. If the blob is not available on the server, the response will instead contain an error.

##### UploadCheck

UploadCheck asks the server whether blobs can be uploaded to it. For each hash in the request, the server returns a true or false to indicate whether it would accept a given blob for upload. In addition, if any of the hashes in the request is a stream hash and the server has the manifest blob for that stream but is missing some content blobs, it may include the hashes of those content blobs in the response.

##### Upload

Upload sends a blob to the server. If uploading many blobs, the client should use the UploadCheck request to check which blobs the server actually needs. This avoids needlessly uploading blobs that the server already has. If a client tries to upload too many blobs that the server does not want, this may be consider a denial of service attack.


The protocol calls and message types are defined in detail [here](https://github.com/lbryio/lbry.go/blob/master/blobex/blobex.proto).




### Reflectors and Data Markets

In order for a client to download content, there must be hosts online that have the content the client wants, when the client wants it. To incentivize the continued hosting of data, the blob exchange protocol supports data upload and payment for data. _Reflectors_ are hosts that accept data uploads. They rehost (reflect) the uploaded data and charge for downloads. Using a reflector is optional, but most publishers will probably choose to use them. Doing so obviates the need for the publisher's server to be online and connectable, which can be especially useful for mobile clients or those behind a firewall.

The current version of the protocol does not support sophisticated price negotiation between clients and hosts. The host simply chooses the price it will charge. Clients check this price before downloading, and pay the price after the download is complete. Future protocol versions will include more options for price negotiation, as well as stronger proofs of payment.



---


_Edit this on Github: https://github.com/lbryio/spec_

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
