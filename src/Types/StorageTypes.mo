import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import Blob "mo:base/Blob";

module {

  // public type Service = actor {
  //   getFileInfo : shared DataId -> async ?MetaInfo;
  //   getSize : shared () -> async Nat;
  //   putChunks : shared (DataId, Nat, Blob) -> async ?();
  //   putFile : shared (MetaInfo, Blob) -> async ?DataId;
  // };

  public type Timestamp = Int; // See mo:base/Time and Time.now()

  public type MetaData = Blob;

  public type DataId = Text;

  public type MetaInfo = {
    isFragment : Nat;
    encodeType : Text;
    eneryptAlg : Text;
    extraData : Text;
    mimeType : MIMEType;
  };

  public type ProtectedMetaInfo = {
    dataId : ?DataId;
    error : ?Text;
  };

  public type MIMEType = {
    #text_plain;
    #text_html;
    #image_jpeg;
    #image_png;
    #audio_mpeg;
    #audio_ogg;
    #audio_any;
    #video_mp4;
    #application;
    #application_json;
    #application_javascript;
    #application_ecmascript;
  };

  public type Map<X, Y> = TrieMap.TrieMap<X, Y>;

}