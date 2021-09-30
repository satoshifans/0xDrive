import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";

import Storage "./Storage";
import FileManager "./FileManager";

shared(msg) actor class OxDrive() = this {

  public type StorageInfo = {
    owner: Principal;
  };

  private stable var _owner: Principal = msg.caller;
  private stable var numStorages: Nat = 0;
  private stable var numFileManager : Nat = 8;
  private stable var cyclesPerStorage: Nat = 2000000000000; // 2 trillion cycles for each storage canister
  private stable var fileManagerList : [Principal] = [];

  private stable var storageEntries : [(Principal, StorageInfo)] = [];
  private var storages = HashMap.HashMap<Principal, StorageInfo>(0, Principal.equal, Principal.hash);

  public type Stats = {
    owner: Principal;
    cyclesPerStorage: Nat;
    cycles: Nat;
  };

  type CanisterSettings = {
    controllers : ?[Principal];
    compute_allocation : ?Nat;
    memory_allocation : ?Nat;
    freezing_threshold : ?Nat;
  };
  type CanisterId = {
    canister_id: Principal;
  };
  type InstallMode = {
    #install;
    #reinstall;
    #upgrade;
  };
  type InstallCodeParams = {
    mode: InstallMode;
    canister_id: Principal;
    wasm_module: Blob;
    arg: Blob;
  };
  type UpdateSettingsParams = {
    canister_id: Principal;
    settings: CanisterSettings;
  };
  type Status = {
    #running;
    #stopping;
    #stopped;
  };
  type CanisterStatus = {
    status: Status;
    settings: CanisterSettings;
    module_hash: ?Blob;
    memory_size: Nat;
    cycles: Nat;
  };
  public type ICActor = actor {
    create_canister: shared(settings: ?CanisterSettings) -> async CanisterId;
    update_settings: shared(params: UpdateSettingsParams) -> async ();
    install_code: shared(params: InstallCodeParams) -> async ();
    canister_status: query(canister_id: CanisterId) -> async CanisterStatus;
  };
  let IC: ICActor = actor("aaaaa-aa");

  system func preupgrade() {
    storageEntries := Iter.toArray(storages.entries());
  };

  system func postupgrade() {
    storages := HashMap.fromIter<Principal, StorageInfo>(storageEntries.vals(), 1, Principal.equal, Principal.hash);
    storageEntries := [];
  };

  public shared(msg) func initFileManagers() : async [Principal] {
    if (Iter.size(fileManagerList.vals()) >= numFileManager){
      return fileManagerList;
    };
    for (i in Iter.range(1, numFileManager)) {
      Cycles.add(cyclesPerStorage);
      let fileManager = await FileManager.FileManager(Principal.fromActor(this));
      let cid = Principal.fromActor(fileManager);
      fileManagerList := Array.append(
        fileManagerList, Array.make<Principal>(cid)
      );
    };
    fileManagerList;
  };

  public shared(msg) func createStorage() : async Principal {
    Cycles.add(cyclesPerStorage);
    let storage = await Storage.Storage(fileManagerList);
    let cid = Principal.fromActor(storage);
    let info: StorageInfo = {
      index = numStorages;
      owner = msg.caller;
      canisterId = cid;
    };
    storages.put(cid, info);
    numStorages += 1;
    return cid;
  };

  public shared(msg) func setController(canisterId: Principal): async Bool {
    switch(storages.get(canisterId)) {
      case(?info) {
        assert(msg.caller == info.owner);
        let controllers: ?[Principal] = ?[msg.caller, Principal.fromActor(this)];
        let settings: CanisterSettings = {
          controllers = controllers;
          compute_allocation = null;
          memory_allocation = null;
          freezing_threshold = null;
        };
        let params: UpdateSettingsParams = {
          canister_id = canisterId;
          settings = settings;
        };
        await IC.update_settings(params);
        return true;
      };
      case(_) { return false };
    }
  };

  public shared(msg) func initUserCanisterCycles(n: Nat) {
    assert(msg.caller == _owner);
    cyclesPerStorage := n;
  };

  public shared(msg) func setOwner(newOwner: Principal) {
    assert(msg.caller == _owner);
    _owner := newOwner;
  };

  public query func getCyclesBalance(): async Nat {
    return Cycles.balance();
  };

  public query func getStorageCount(): async Nat {
    return numStorages;
  };

  public query func getStats(): async Stats {
    return {
      owner = _owner;
      numStorages = numStorages;
      cyclesPerStorage = cyclesPerStorage;
      cycles = Cycles.balance();
    };
  };

    public shared(msg) func getSysStatus(canister_id: Principal): async ?CanisterStatus {
      let param: CanisterId = {
        canister_id = canister_id;
      };
      let status = await IC.canister_status(param);
      return ?status;
  };

  public shared(msg) func getUserCanisterStatus(canister_id: Principal): async ?CanisterStatus {
    switch(storages.get(canister_id)) {
      case(?info) {
        let param: CanisterId = {
          canister_id = canister_id;
        };
        let status = await IC.canister_status(param);
        return ?status;
      };
      case(_) {return null};
    }
  };

  public query func getFileManagersList(): async [Principal] {
    fileManagerList;
  };

  public query func getCanisterList(): async [StorageInfo] {
    var storageList: [StorageInfo] = [];
    for((index, storage) in storages.entries()) {
      storageList := Array.append<StorageInfo>(storageList, [storage]);
    };
    storageList
  };

  public query func getUserCanisterList(user: Principal): async [StorageInfo] {
    var storageList: [StorageInfo] = [];
    for((index, storage) in storages.entries()) {
      if(storage.owner == user) {
        storageList := Array.append<StorageInfo>(storageList, [storage]);
      };
    };
    storageList
  };

  public query func getStorageInfo(cid: Principal): async ?StorageInfo {
    storages.get(cid)
  };
};