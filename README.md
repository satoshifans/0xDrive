

<img src="https://cdn.discordapp.com/attachments/891583129452691456/892730559162384384/0xdrive-logo.png" alt="avatar" width = "500" height = "110" alt="" style="text-align:center" />

- [About](#about-about)
- [Technology](#technology)
- [Smart Contracts](#smart-contracts)
  * [1. Deploy](#1-deploy)
    + [1.1 Installing dfx sdk](#11-installing-dfx-sdk)
    + [1.2 Start dfx local network](#12-start-dfx-local-network)
    + [1.3 Deploy local canister](#13-deploy-local-canister)
    + [1. 4 Init FileManager](#1-4-init-filemanager)
  * [2. Implemented functions](#2-implemented-functions)
    + [2.1 putFile Raw storage interface](#21-putfile-raw-storage-interface)
    + [2.2 getFile Original query interface](#22-getfile-original-query-interface)
    + [2.3 User canister management](#23-user-canister-management)
      - [2.3.1  Create user storage](#231--create-user-storage)
      - [2.3.2 Check the status of a canister tank](#232-check-the-status-of-a-canister-tank)
      - [2.3.3 View the list of canister for a particular user](#233-view-the-list-of-canister-for-a-particular-user)
- [Features being implemented](#features-being-implemented)
- [SDK (to be implemented)](#sdk-to-be-implemented)


## About

0xDrive is a decentralized private data storage and transaction protocol based on ICP network, where users have full control over their data. Users store their private data on the ICP network through encryption, free from the control of traditional data storage providers. Users can share their data to specific entities, enabling authorization through permission signatures, proxy re-encryption, etc. 0xDrive issues data as NFTs to enable the flow and trading of private data. For example, users can store copyrighted data such as written creations, artworks, photos, etc. on ICP networks to assert copyright and make them tradable. 0xDrive is a storage and transaction protocol that develops a unified application programming interface specification to support the storage and application of privacy data on decentralized networks such as IPFS and ICP. 

## Technology

0xDrive develops a unified application programming interface specification, including encryption, decryption, storage, reading, slicing and other functions for data, and will be implemented as an open source SDK. 0xDrive is also a storage Hub that can support data storage on different decentralized networks such as IPFS and ICP.

<img src="https://cdn.discordapp.com/attachments/891583129452691456/892730712237678592/20210929190649.png" alt="avatar"  width = "500" height = "400" />

## Smart Contracts

### 1. Deploy

#### 1.1 Installing dfx sdk

Before starting OxDrive you need to install dfx sdk locally, if there is already a local dfx environment you can ignore this step.

*tips: needs to be executed on macOS or Linux systems*

````sh
sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"
````

#### 1.2 Start dfx local network

Note that the command should be executed under the project path.

````sh
dfx start --clean
````

output：...Sep 28 10:58:37.520 INFO Starting server. Listening on http://0.0.0.0:8000 ,Indicates a successful start on the 8000

#### 1.3 Deploy local canister

Note to execute this command in the project path. Create and deploy the OxDrive canister. The corresponding contract is `OxDrive.mo`

```` sh
dfx deploy --with-cycles 80000000000000
````

*tips: If the initialized cycles if too small, the creation of NFT containers later will prompt insufficient cycles*

#### 1. 4 Init FileManager 

- System canister initialization interface, this method will initialize 8 canister. as jars for NFT storage management. Corresponding contract is `FileManager.mo`

*tip: this initialization process will be integrated into deploy in the future.*

- Calling example

````sh
dfx canister --no-wallet call OxDrive initFileManagers
````

- Return example

````
(
  vec {
    principal "r7inp-6aaaa-aaaaa-aaabq-cai";
    principal "rkp4c-7iaaa-aaaaa-aaaca-cai";
    principal "rno2w-sqaaa-aaaaa-aaacq-cai";
    principal "renrk-eyaaa-aaaaa-aaada-cai";
    principal "rdmx6-jaaaa-aaaaa-aaadq-cai";
    principal "qoctq-giaaa-aaaaa-aaaea-cai";
    principal "qjdve-lqaaa-aaaaa-aaaeq-cai";
    principal "qaa6y-5yaaa-aaaaa-aaafa-cai";
  },
)
````



### 2. Implemented functions

#### 2.1 putFile Raw storage interface

- **Request parameter description:**

  | Name       | Type       | Require | Description          |
  | ---------- | ---------- | ------- | -------------------- |
  | `metaInfo` | `MetaInfo` | `true`  | Metadata Information |
  | `data`     | `Blob`     | `true`  | Data Binary          |

  **metaInfo**

  | Name          | Type     | Require | Description                                                 |
  | ------------- | -------- | ------- | ----------------------------------------------------------- |
  | dataId        | Text     | false   | Existing document ID is modified, leave blank is added      |
  | mimeType      | MIMEType | true    | MIME type of the file                                       |
  | isFragment    | Nat      | true    | Is the file sharded 0 - non-sharded ,1 - total ,2 - sharded |
  | encodeType    | Text     | true    | Document encoding standards                                 |
  | encryptionAlg | Text     | false   | Encryption algorithm, leave blank for unencrypted           |
  | extraData     | Text     | false   | Extra Information                                           |

- Calling example

  ````sh
  dfx canister call qhbym-qaaaa-aaaaa-aaafq-cai putFile '(record {metaInfo = record {isFragment = 0:nat;encodeType = "Text";eneryptAlg = "Text";extraData = "Text";mimeType = variant {"text_plain"}};data = blob "hello world"})'
  ````

- Return example

  ````
  (
    opt record {
      opt "D4994457F0FA95CDC7A61E29D7AC542D236D0DACB20A1CB256AB3908AB757632";
      1 : nat;
    },
  )
  ````


#### 2.2 getFile Original query interface

- Request parameter description

| Name     | Type   | Require | Description |
| -------- | ------ | ------- | ----------- |
| `dataId` | `Text` | `True`  | File id     |

- Calling example

````sh
dfx canister call qhbym-qaaaa-aaaaa-aaafq-cai getFile '("55DCB6796D87FE404F720C358E39226519BF47C90E2E30008B9E49E6F00D2611")'
````

- Return example

````
(
  opt blob "\89PNG\0d\0a\1a\0a\00\00\00\0dIHDR\00\00\03\b4\00\00\00\d8\08\06\00\00\00\db\19\af\12\00\00\00\01sRGB\00\ae\ce\1c\e9\00\00\00\04gAMA\00\00\b1\8f\0b\fca\05\00\00\00\09pHYs\00\00\0e\c3\00\00\0e\c3\01\c7o\a8d\00\00\00!tEXtCreation Time\002021:09:28 14:59:11\e4H\adi\00\00R\80IDATx^\ed\dd\07\9c$U\f1\07\f0\aa\de\db=r\06\b3\22Y\01\81?\08f@$\88\01T\10\15\15\94\a4HN\b7\b3w\fe\97\d5\dbp \92\14\10D\c9*QQ\89\fe\81\13\11%\a8 \88d\05\13I$\08\dc\eem\d7\bf\aa\bb\ee\80\e3\c2\ce\ee\cctu\cf\ef\fb\b9\99y\f5vo\a7\fb\bd\9e\ee~\d3\af\df#\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80qa\7f\05\00\00\00\80\a8j\e9\ca\fa\bc\ad\9e\b9mAB\ebkz5}\ac@\cc\09\89\a4\9a\fe\b7>\1e\d0\c7\ed\fa\98\a9\8f+i0yL_\01\00*\0d\0dZ\00\00\00\80\a8\a6\8a6\60\e5\60m\c4n\af\8d\d7I\9e\bbh\22\b3\f5,\ef2\fd?\c7R?_\e7\b9\00\00\95\83\06-\00\00\00@4\d3\d2\b7\d0(}K\1b\a4\ef\f7\9c\f1\1
  ...
  ...
  ...\IEND\aeB\60\82",
)

````

#### 2.3 User canister management

##### 2.3.1  Create user storage

- The user creates a storage canister to create a separate container for the user to store the user's data. The corresponding contract is `Storage.mo`

- Request parameter description

| Name        | Type        | Require | Description                  |
| ----------- | ----------- | ------- | ---------------------------- |
| `principal` | `principal` | `True`  | The principal ID of the user |

- Calling example

````sh
dfx canister call OxDrive createStorage '(principal "p23sz-nsgne-cvycp-tdk5p-qicli-witvu-rwba4-avncn-mhurv-sebmx-nae")' --type idl

````

- Return example

````
(principal "qhbym-qaaaa-aaaaa-aaafq-cai")
````

##### 2.3.2 Check the status of a canister tank

- Request parameter description

| Name        | Type        | Require | Description                  |
| ----------- | ----------- | ------- | ---------------------------- |
| `principal` | `principal` | `True`  | The principal ID of the user |

- Calling example

````sh
dfx canister call OxDrive getUserCanisterStatus '(principal "qhbym-qaaaa-aaaaa-aaafq-cai")' --type idl
````

- Return example

````
(
  opt record {
    status = variant { running };
    memory_size = 454_747 : nat;
    cycles = 2_000_000_000_000 : nat;
    settings = record {
      freezing_threshold = opt (2_592_000 : nat);
      controllers = opt vec { principal "rrkah-fqaaa-aaaaa-aaaaq-cai" };
      memory_allocation = opt (0 : nat);
      compute_allocation = opt (0 : nat);
    };
    module_hash = opt blob "\f0\c8\00\cd\fd\9f;O\c6\8b\b75\a0\12\d3\c9)}\ec\f8\e54V\95\d0\bc\1a8\a1\1eG\8b";
  },
)
````

##### 2.3.3 View the list of canister for a particular user

- Request parameter description

| Name        | Type        | Require | Description                  |
| ----------- | ----------- | ------- | ---------------------------- |
| `principal` | `principal` | `True`  | The principal ID of the user |

- Calling example

````sh
dfx canister call OxDrive getUserCanisterList '(principal "p23sz-nsgne-cvycp-tdk5p-qicli-witvu-rwba4-avncn-mhurv-sebmx-nae")' --type idl
````

- Return example

````
(
  vec {
    record {
      owner = principal "3rpzj-jp7vd-zfai5-zhllw-pqqxi-7bfer-mds4c-5rrpo-nkgq7-3bkrg-oqe";
    };
  },
)
````



## Features being implemented

1. Get file metadata information

2. Get metadata information of all files in the current jar

3.  NFT implementation

4. Data Access License Implementation

## SDK (to be implemented)

1. Definition of "record"

2. Document Slice Specification

3. SDK operation interface encapsulation
