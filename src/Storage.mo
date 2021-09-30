import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Hex "./Util/Hex";
import SHA256 "./Util/SHA256";
import AID "./Util/AccountIdentifier";
import Types "./Types/StorageTypes";
import Result "mo:base/Result";
import ExtCommon "./ERC1155/Common";
import ExtCore "./ERC1155/Core";

shared(msg) actor class Storage(initFileManagerList : [Principal]) = this {

  type DataId = Types.DataId;
  type MetaInfo = Types.MetaInfo;
  type MetaData = Types.MetaData;
  type ProtectedMetaInfo = Types.ProtectedMetaInfo;
  type PutFileRequest = {
    metaInfo : MetaInfo;
    data : Blob;
  };

  type RegisterTokenRequest = {
    metadata : ExtCommon.Metadata;
    supply : ExtCore.Balance;
    owner : ExtCore.AccountIdentifier;
  };
  public type FileManager = actor {
    registerToken: shared(request: RegisterTokenRequest) -> async Result.Result<ExtCore.TokenIndex,Text>;
  };

  private var metaInfoState = TrieMap.TrieMap<DataId, MetaInfo>(Text.equal, Text.hash);
  private var metaDataState = TrieMap.TrieMap<DataId, MetaData>(Text.equal, Text.hash);

  private stable var fileManagerList : [Principal] = initFileManagerList;
  private stable var metaInfoEntries : [(DataId, MetaInfo)] = [];
  private stable var metaDataEntries : [(DataId, MetaData)] = [];

  // writes the current map entries to stable memory entries
  system func preupgrade() {
    metaInfoEntries := Iter.toArray(metaInfoState.entries());
    metaDataEntries := Iter.toArray(metaDataState.entries());
  };

  // restroe map from entries && resets entries to the empty array
  system func postupgrade() {
    metaInfoState := TrieMap.fromEntries<DataId, MetaInfo>(metaInfoEntries.vals(), Text.equal, Text.hash);
    metaInfoEntries := [];
    metaDataState := TrieMap.fromEntries<DataId, MetaData>(metaDataEntries.vals(), Text.equal, Text.hash);
    metaDataEntries := [];
  };

  public func getSize(): async Nat {
    Debug.print("canister balance: " # Nat.toText(Cycles.balance()));
    Debug.print("canister balance: " # Nat.toText(Cycles.balance()));
    Prim.rts_memory_size();
  };

  // Calculate dataId 
  // dataId = sha256(sha256(this canister Id) + sha256(data))
  public func getDataId(data: Blob) : async (Text, Nat) {
    let canisterId : Text = Principal.toText(Principal.fromActor(this));
    let cidHash = SHA256.sha256(Blob.toArray(Text.encodeUtf8(canisterId)));
    let dataHash = getHash(data);
    let msg = Array.append(cidHash, dataHash);
    // Debug.print(debug_show(canisterId));
    // Debug.print(debug_show(Text.encodeUtf8(canisterId)) # "hash: " # debug_show(cidHash) # "hex:" # Hex.encode(cidHash)); 
    // Debug.print(debug_show(msg));
    let sha = SHA256.sha256(msg);
    let dataId = Hex.encode(sha);
    let index = Nat8.toNat(sha[31] & 7);
    return (dataId, index);
  };

  // from Blob to hash
   func getHash(data: Blob) :  [Nat8] {
    // Debug.print("Blob" # debug_show(Blob.toArray(data)));
    let sha = SHA256.sha256(Blob.toArray(data));
    return sha;
  };

  func createMetaInfo(dataId: Text, metaInfo: MetaInfo) : ProtectedMetaInfo {
    switch (metaInfoState.get(dataId)) {
      case (?_) {
        /* error -- ID already taken. */
        // Error.reject("ID Already Taken");
        // null
        return {
          dataId = null;
          error = ?"ID Already Taken";
        }
      };
      case null { /* ok, not taken yet. */
        Debug.print("dataId is..." # debug_show(dataId));
        metaInfoState.put(dataId,
          {
            isFragment = metaInfo.isFragment;
            encodeType = metaInfo.encodeType;
            eneryptAlg = metaInfo.eneryptAlg;
            extraData = metaInfo.extraData;
            mimeType = metaInfo.mimeType;
          }
        );
        return {
          dataId = ?dataId;
          error = null;
        }
      };
    }
  };

  public shared(msg) func putFile(request : PutFileRequest) : async ?(?DataId,Nat) {
    let data = request.data;
    let metaInfo = request.metaInfo;
    do ? {
      // generate dataId by calculating data hash with SHA-256
      let (newDataId, cidIndex) = await getDataId(data);

      Debug.print("generated data id is " # debug_show(newDataId) # " and data size:" # debug_show(Blob.toArray(data).size()) );

      metaDataState.put(newDataId, data);

      let({error; dataId}) : ProtectedMetaInfo = createMetaInfo(newDataId, metaInfo);

      switch (error) {
        case (?error) {
            throw Error.reject(error);
        };
        case null {
          let cid = Principal.toText(fileManagerList[cidIndex]);
          let fileManager : FileManager = actor(cid);
          switch(await fileManager.registerToken({
                metadata = #Nonfungible({
                  name = null;
                  symbol = null;
                  location = "IC:" # Principal.toText(Principal.fromActor(this));
                  canisterId = Principal.fromActor(this);
                  dataId = newDataId;
                  dataHash = newDataId;
                });
                supply = 1;
                owner = AID.fromPrincipal(msg.caller, null);
              })){
            case(#ok(tokenId)){
              Debug.print("Owner: " # debug_show(AID.fromPrincipal(msg.caller, null)));
              return ?(dataId,cidIndex);
            };
            case(#err(err)){
              return null;
            }
          };
        };
      };
    }
  };

  func getFileInfoData(dataId : DataId) : ?MetaInfo {
    do ? {
      let thisMetaInfo = metaInfoState.get(dataId)!;
        {
          isFragment = thisMetaInfo.isFragment;
          encodeType = thisMetaInfo.encodeType;
          eneryptAlg = thisMetaInfo.eneryptAlg;
          extraData = thisMetaInfo.extraData;
          mimeType = thisMetaInfo.mimeType;
        }
    }
  };

  public query func getFileInfo(dataId : DataId) : async ?MetaInfo {
    do ? {
      getFileInfoData(dataId)!
    }
  };

  public query func getFile(dataId : DataId) : async ?Blob {
    metaDataState.get(dataId)
  };

  public query func getAllMetaInfo() : async [MetaInfo] {
    let b = Buffer.Buffer<MetaInfo>(0);
    let _ = do ? {
      for ((f, _) in metaInfoState.entries()) {
        b.add(getFileInfoData(f)!)
      };
    };
    b.toArray()
  };

}