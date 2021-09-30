/**

 */
import Result "mo:base/Result";

import ExtCore "./Core";
module ExtCommon = {
  public type Metadata = {
    #Fungible : {
      name : Text;
      symbol : Text;
      decimals : Nat8;
      location : Text;
      canisterId : Principal;
      dataId : Text;                // 取数据
      dataHash : Text;              // sha256
    };
    #Nonfungible : {
      name : ?Text;
      symbol : ?Text;
      location : Text;
      canisterId : Principal;
      dataId : Text;                // 取数据
      dataHash : Text;              // sha256
    };
  };
  public type Service = actor {
    metadata: query (token : ExtCore.TokenIdentifier) -> async Result.Result<Metadata, ExtCore.CommonError>;

    supply: query (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;
  };
};