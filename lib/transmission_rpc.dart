library transmission_rpc;

import 'dart:html';
import 'dart:convert';

class Transmission{

  String url;
  String user;
  String password;
  String sessionId;
  int rpc = 0;
  int tag = 0;

  Transmission(String host, {String port, String user, String password}){

    if(user!=null){
      this.user = user;
    }
    if(password!=null){
      this.password = password;
    }
    if(port!=null){
      this._createURL(host,port);
    }else{
      this._createURL(host,"9091");
    }
    this.updateSessionID();
    this.updateRpcVersion();

  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////  UTILITIES       ///////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  void _createURL(String host, String port){
    String url = "";
    if(this.user!=null && this.password!=null){
      url+="http://" + this.user + ":" + this.password+ "@" + host + ":" + port + "/transmission/rpc";
    }else{
      url+="http://" + host + ":" + port + "/transmission/rpc";
    }
    this.url = url;
  }

  void updateSessionID(){

    Map data = new Map();
    data["method"] = "rcp-test";
    data["arguments"] = "";
    data["tag"] = this.tag;
    String jsonData = JSON.encode(data);

    HttpRequest request = new HttpRequest();

    request.onReadyStateChange.listen((_) {
      if (request.status == 409) {
        this.sessionId = request.getResponseHeader("X-Transmission-Session-Id");
      }
    });

    request.open("POST",this.url,async:false,user: this.user, password: this.password);
    request.send(jsonData);
    this.tag++;
  }

  void updateRpcVersion(){
    Map data = new Map();
    data["method"] = "session-get";
    data["arguments"] = new Map();
    data["tag"] = this.tag;
    String jsonData = JSON.encode(data);
    HttpRequest request = new HttpRequest();
    request.onReadyStateChange.listen((_) {
      if (request.status == 409) {
        this.updateSessionID();
      }
    });
    request.open("POST",this.url,async:false,user: this.user, password: this.password);
    if(this.sessionId != null)
      request.setRequestHeader("X-Transmission-Session-Id", sessionId);
    request.send(jsonData);
    this.tag++;
    Map response = JSON.decode(request.responseText);
    this.rpc = response["arguments"]["rpc-version"];
  }

  String sendCommand(String method, Map parameters){

    Map data = new Map();
    data["method"] = method;
    data["arguments"] = parameters;
    data["tag"] = this.tag;
    String jsonData = JSON.encode(data);

    HttpRequest request = new HttpRequest();
    request.onReadyStateChange.listen((_) {
      if (request.status == 409) {
        this.updateSessionID();
      }
    });
    request.open("POST",this.url,async:false,user: this.user, password: this.password);
    if(this.sessionId != null)
      request.setRequestHeader("X-Transmission-Session-Id", sessionId);
    request.send(jsonData);
    this.tag++;
    return request.responseText;
  }

  List<Map> _torrentsFromJSON(String jsonData){
    Map parsedMap = JSON.decode(jsonData);
    Map arguments = parsedMap["arguments"];
    List torrents = arguments["torrents"];
    return torrents;
  }

  List _torrentsFilter(int status){
    Map arguments = new Map();
    arguments["fields"] = ["id","status"];
    List torrents = _torrentsFromJSON(this.sendCommand("torrent-get",arguments));
    List ids=[];
    for(Map torrent in torrents){
      if(torrent["status"] == status){
        ids.add(torrent["id"]);
      }
    }
    return ids;
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////  METHODS         ///////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  /*
    DESCRIPTION: get torrents
    PARAMETERS:
      - List <int> ids -> list of ids of the torrents to get. If the array is empty it will get all torrents
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments
  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map>  getTorrent(List<int>ids, List<String> fields){
    Map arguments = new Map();
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    arguments["fields"] = fields;
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));

  }

  /*
    DESCRIPTION: set torrents
    PARAMETERS:
      - List <int> ids -> list of ids of the torrents to get. If the array is empty it will get all torrents
      - Map attributes -> parameters to be set
    RETURN:
      - String -> response of the server
  */

  //Request arguments
  /*
   string                            | value type & description
   ----------------------------------+-------------------------------------------------
   "bandwidthPriority"               | number     this torrent's bandwidth tr_priority_t
   "downloadLimit"                   | number     maximum download speed (in K/s)
   "downloadLimited"                 | boolean    true if "downloadLimit" is honored
   "files-wanted"                    | array      indices of file(s) to download
   "files-unwanted"                  | array      indices of file(s) to not download
   "honorsSessionLimits"             | boolean    true if session upload limits are honored
   "ids"                             | array      torrent list, as described in 3.1
   "location"                        | string     new location of the torrent's content
   "peer-limit"                      | number     maximum number of peers
   "priority-high"                   | array      indices of high-priority file(s)
   "priority-low"                    | array      indices of low-priority file(s)
   "priority-normal"                 | array      indices of normal-priority file(s)
   "seedRatioLimit"                  | double     session seeding ratio
   "seedRatioMode"                   | number     which ratio to use.  See tr_ratiolimit
   "uploadLimit"                     | number     maximum upload speed (in K/s)
   "uploadLimited"                   | boolean    true if "uploadLimit" is honored

   Just as an empty "ids" value is shorthand for "all ids", using an empty array
   for "files-wanted", "files-unwanted", "priority-high", "priority-low", or
  "priority-normal" is shorthand for saying "all files".
   */

  String setTorrent(List<int>ids, Map attributes){
    Map arguments = new Map();
    arguments = attributes;
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    return this.sendCommand("torrent-set",arguments);
  }

  /*
    DESCRIPTION: get torrents downloading
    PARAMETERS:
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments

  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map> getDownloadingTorrents(List<String>fields){
    Map arguments = new Map();
    arguments["fields"] = fields;
    arguments["ids"] = _torrentsFilter(4);
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));
  }

  /*
    DESCRIPTION: get torrents in the queue for downloading
    PARAMETERS:
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments

  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map> getDownloadingWaitTorrents(List<String>fields){
    Map arguments = new Map();
    arguments["fields"] = fields;
    if(rpc == 14){
      arguments["ids"] = _torrentsFilter(3);
    }else{
      arguments["ids"] = _torrentsFilter(0);
    }
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));
  }

  /*
    DESCRIPTION: get torrents sending
    PARAMETERS:
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments

  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map> getSendingTorrents(List<String>fields){
    Map arguments = new Map();
    arguments["fields"] = fields;
    if(rpc == 14){
      arguments["ids"] = _torrentsFilter(6);
    }else{
      arguments["ids"] = _torrentsFilter(8);
    }
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));

  }

/*
    DESCRIPTION: get torrents in the sending queue
    PARAMETERS:
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments

  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map> getSendingWaitTorrents(List<String>fields){
    Map arguments = new Map();
    arguments["fields"] = fields;
    if(rpc == 14){
      arguments["ids"] = _torrentsFilter(5);
    }else{
      arguments["ids"] = _torrentsFilter(0);
    }
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));
  }

  /*
    DESCRIPTION: get torrents paused or stopped
    PARAMETERS:
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments

  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map> getPausedTorrents(List<String>fields){
    Map arguments = new Map();
    arguments["fields"] = fields;
    if(rpc == 14){
      arguments["ids"] = _torrentsFilter(0);
    }else{
      arguments["ids"] = _torrentsFilter(16);
    }
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));
  }

  /*
    DESCRIPTION: get torrents checking
    PARAMETERS:
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments

  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map> checkingTorrents(List<String>fields){
    Map arguments = new Map();
    arguments["fields"] = fields;
    arguments["ids"] = _torrentsFilter(2);
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));
  }

  /*
    DESCRIPTION: get torrents in the checking queue
    PARAMETERS:
      - List <String> fields -> list of the parameters of the to torrents that will be return
    RETURN:
      - List <Map> -> Each map contains the information of a torrent
  */
  //Fields arguments

  /*
       key                             | type                        | source
      --------------------------------+-----------------------------+---------
       activityDate                    | number                      | tr_stat
       addedDate                       | number                      | tr_stat
       announceResponse                | string                      | tr_stat
       announceURL                     | string                      | tr_stat
       bandwidthPriority               | number                      | tr_priority_t
       comment                         | string                      | tr_info
       corruptEver                     | number                      | tr_stat
       creator                         | string                      | tr_info
       dateCreated                     | number                      | tr_info
       desiredAvailable                | number                      | tr_stat
       doneDate                        | number                      | tr_stat
       downloadDir                     | string                      | tr_torrent
       downloadedEver                  | number                      | tr_stat
       downloaders                     | number                      | tr_stat
       downloadLimit                   | number                      | tr_torrent
       downloadLimited                 | boolean                     | tr_torrent
       error                           | number                      | tr_stat
       errorString                     | string                      | tr_stat
       eta                             | number                      | tr_stat
       files                           | array (see below)           | n/a
       fileStats                       | array (see below)           | n/a
       hashString                      | string                      | tr_info
       haveUnchecked                   | number                      | tr_stat
       haveValid                       | number                      | tr_stat
       honorsSessionLimits             | boolean                     | tr_torrent
       id                              | number                      | tr_torrent
       isPrivate                       | boolean                     | tr_torrent
       lastAnnounceTime                | number                      | tr_stat
       lastScrapeTime                  | number                      | tr_stat
       leechers                        | number                      | tr_stat
       leftUntilDone                   | number                      | tr_stat
       manualAnnounceTime              | number                      | tr_stat
       maxConnectedPeers               | number                      | tr_torrent
       name                            | string                      | tr_info
       nextAnnounceTime                | number                      | tr_stat
       nextScrapeTime                  | number                      | tr_stat
       peer-limit                      | number                      | tr_torrent
       peers                           | array (see below)           | n/a
       peersConnected                  | number                      | tr_stat
       peersFrom                       | object (see below)          | n/a
       peersGettingFromUs              | number                      | tr_stat
       peersKnown                      | number                      | tr_stat
       peersSendingToUs                | number                      | tr_stat
       percentDone                     | double                      | tr_stat
       pieces                          | string (see below)          | tr_torrent
       pieceCount                      | number                      | tr_info
       pieceSize                       | number                      | tr_info
       priorities                      | array (see below)           | n/a
       rateDownload (B/s)              | number                      | tr_stat
       rateUpload (B/s)                | number                      | tr_stat
       recheckProgress                 | double                      | tr_stat
       scrapeResponse                  | string                      | tr_stat
       scrapeURL                       | string                      | tr_stat
       seeders                         | number                      | tr_stat
       seedRatioLimit                  | double                      | tr_torrent
       seedRatioMode                   | number                      | tr_ratiolimit
       sizeWhenDone                    | number                      | tr_stat
       startDate                       | number                      | tr_stat
       status                          | number                      | tr_stat
       swarmSpeed (K/s)                | number                      | tr_stat
       timesCompleted                  | number                      | tr_stat
       trackers                        | array (see below)           | n/a
       totalSize                       | number                      | tr_info
       torrentFile                     | string                      | tr_info
       uploadedEver                    | number                      | tr_stat
       uploadLimit                     | number                      | tr_torrent
       uploadLimited                   | boolean                     | tr_torrent
       uploadRatio                     | double                      | tr_stat
       wanted                          | array (see below)           | n/a
       webseeds                        | array (see below)           | n/a
       webseedsSendingToUs             | number                      | tr_stat
                                       |                             |
                                       |                             |
       -----------------------+--------+-----------------------------+
       files                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | key                     | type       |
                              | bytesCompleted          | number     | tr_torrent
                              | length                  | number     | tr_info
                              | name                    | string     | tr_info
       -----------------------+--------------------------------------+
       fileStats              | a file's non-constant properties.    |
                              | array of tr_info.filecount objects,  |
                              | each containing:                     |
                              +-------------------------+------------+
                              | bytesCompleted          | number     | tr_torrent
                              | wanted                  | boolean    | tr_info
                              | priority                | number     | tr_info
       -----------------------+--------------------------------------+
       peers                  | array of objects, each containing:   |
                              +-------------------------+------------+
                              | address                 | string     | tr_peer_stat
                              | clientName              | string     | tr_peer_stat
                              | clientIsChoked          | boolean    | tr_peer_stat
                              | clientIsInterested      | boolean    | tr_peer_stat
                              | isDownloadingFrom       | boolean    | tr_peer_stat
                              | isEncrypted             | boolean    | tr_peer_stat
                              | isIncoming              | boolean    | tr_peer_stat
                              | isUploadingTo           | boolean    | tr_peer_stat
                              | peerIsChoked            | boolean    | tr_peer_stat
                              | peerIsInterested        | boolean    | tr_peer_stat
                              | port                    | number     | tr_peer_stat
                              | progress                | double     | tr_peer_stat
                              | rateToClient (B/s)      | number     | tr_peer_stat
                              | rateToPeer (B/s)        | number     | tr_peer_stat
       -----------------------+--------------------------------------+
       peersFrom              | an object containing:                |
                              +-------------------------+------------+
                              | fromCache               | number     | tr_stat
                              | fromIncoming            | number     | tr_stat
                              | fromPex                 | number     | tr_stat
                              | fromTracker             | number     | tr_stat
       -----------------------+--------------------------------------+
       pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                              | which are set to 'true' if we have   |
                              | the piece matching that position.    |
                              | JSON doesn't allow raw binary data,  |
                              | so this is a base-encoded string.  |
       -----------------------+--------------------------------------+
       priorities             | an array of tr_info.filecount        | tr_info
                              | numbers. each is the tr_priority_t   |
                              | mode for the corresponding file.     |
       -----------------------+--------------------------------------+
       trackers               | array of objects, each containing:   |
                              +-------------------------+------------+
                              | announce                | string     | tr_info
                              | scrape                  | string     | tr_info
                              | tier                    | number     | tr_info
       -----------------------+--------------------------------------+
       wanted                 | an array of tr_info.fileCount        | tr_info
                              | 'booleans' true if the corresponding |
                              | file is to be downloaded.            |
       -----------------------+--------------------------------------+
       webseeds               | an array of strings:                 |
                              +-------------------------+------------+
                              | webseed                 | string     | tr_info
                              +-------------------------+------------+
   */

  List<Map> checkingWaitTorrents(List<String>fields){
    Map arguments = new Map();
    arguments["fields"] = fields;
    arguments["ids"] = _torrentsFilter(1);
    return _torrentsFromJSON(this.sendCommand("torrent-get",arguments));
  }

  /*
    DESCRIPTION: add torrent from a file o a url
    PARAMETERS:
      - String url -> path to file or url to file
      - Map arg -> Optional -> arguments for the new torrent
    RETURN:
      - String -> response from the server
  */
  //Torrent added options
  /*
  key                | value type & description
  -------------------+-------------------------------------------------
  "download-dir"     | string      path to download the torrent to
  "filename"         | string      filename or URL of the .torrent file
  "metainfo"         | string      base64-encoded .torrent content
  "paused"           | boolean     if true, don't start the torrent
  "peer-limit"       | number      maximum number of peers
  "files-wanted"     | array       indices of file(s) to download
  "files-unwanted"   | array       indices of file(s) to not download
  "priority-high"    | array       indices of high-priority file(s)
  "priority-low"     | array       indices of low-priority file(s)
  "priority-normal"  | array       indices of normal-priority file(s)
   */

  String addTorrent(String url, [Map args]){
    Map arguments = new Map();
    if(args!=null){
      arguments =args;
    }
    arguments["filename"]=url;
    return this.sendCommand("torrent-add",arguments);
  }

  /*
    DESCRIPTION: add multiple torrents from files o urls
    PARAMETERS:
      - List<String> urls -> paths to files or urls to files
    RETURN:
      - List<String> -> responses from the server
  */
  //Torrent added options
  /*
  key                | value type & description
  -------------------+-------------------------------------------------
  "download-dir"     | string      path to download the torrent to
  "filename"         | string      filename or URL of the .torrent file
  "metainfo"         | string      base64-encoded .torrent content
  "paused"           | boolean     if true, don't start the torrent
  "peer-limit"       | number      maximum number of peers
  "files-wanted"     | array       indices of file(s) to download
  "files-unwanted"   | array       indices of file(s) to not download
  "priority-high"    | array       indices of high-priority file(s)
  "priority-low"     | array       indices of low-priority file(s)
  "priority-normal"  | array       indices of normal-priority file(s)
   */

  List<String> addTorrents(List<String>urls){
    List <String> responses = [];
    for(String url in urls){
      responses.add(this.addTorrent(url));
    }
    return responses;
  }


  /*
    DESCRIPTION: start a torrent or multiple torrents
    PARAMETERS:
      - List <int> ids -> ids of the torrent to start. If the array is empty all torrents will start
    RETURN:
      - String -> response from the server
  */


  String startTorrent(List<int> ids){
    Map arguments = new Map();
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    return this.sendCommand("torrent-start",arguments);
  }

  /*
    DESCRIPTION: pause a torrent or multiple torrents
    PARAMETERS:
      - List <int> ids -> ids of the torrent to pause. If the array is empty all torrents will pause
    RETURN:
      - String -> response from the server
  */

  String pauseTorrent(List<int> ids){
    Map arguments = new Map();
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    return this.sendCommand("torrent-stop",arguments);
  }

  /*
    DESCRIPTION: verify a torrent or multiple torrents
    PARAMETERS:
      - List <int> ids -> ids of the torrent to verify. If the array is empty all torrents will verify
    RETURN:
      - String -> response from the server
  */

  String verifyTorrent(List<int> ids){
    Map arguments = new Map();
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    return this.sendCommand("torrent-verify",arguments);
  }

  /*
    DESCRIPTION: remove a torrent or multiple torrents
    PARAMETERS:
      - List <int> ids -> ids of the torrent to remove. If the array is empty all torrents will removed
      - bool deleteLocalData -> Optional -> default: false -> remove local data
    RETURN:
      - String -> response from the server
  */

  String removeTorrent(List<int> ids, [bool deleteLocalData = false]){
    Map arguments = new Map();
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    arguments["delete-local-data"] = deleteLocalData;
    return this.sendCommand("torrent-remove",arguments);

  }

  /*
    DESCRIPTION: reannounce a torrent or multiple torrents
    PARAMETERS:
      - List <int> ids -> ids of the torrent to reannounce. If the array is empty all torrents will reannounce
    RETURN:
      - String -> response from the server
  */

  String reannounceTorrent(List<int> ids){
    Map arguments = new Map();
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    return this.sendCommand("torrent-reannounce",arguments);
  }

  /*
    DESCRIPTION: get session parameters
    PARAMETERS:
    RETURN:
      - Map -> response from the server
  */

  //Session arguments

  /*
         string                     | value type & description
     ---------------------------+-------------------------------------------------
     "alt-speed-down"           | number     max global download speed (in K/s)
     "alt-speed-enabled"        | boolean    true means use the alt speeds
     "alt-speed-time-begin"     | number     when to turn on alt speeds (units: minutes after midnight)
     "alt-speed-time-enabled"   | boolean    true means the scheduled on/off times are used
     "alt-speed-time-end"       | number     when to turn off alt speeds (units: same)
     "alt-speed-time-day"       | number     what day(s) to turn on alt speeds (look at tr_sched_day)
     "alt-speed-up"             | number     max global upload speed (in K/s)
     "blocklist-enabled"        | boolean    true means enabled
     "blocklist-size"           | number     number of rules in the blocklist
     "dht-enabled"              | boolean    true means allow dht in public torrents
     "encryption"               | string     "required", "preferred", "tolerated"
     "download-dir"             | string     default path to download torrents
     "peer-limit-global"        | number     maximum global number of peers
     "peer-limit-per-torrent"   | number     maximum global number of peers
     "pex-enabled"              | boolean    true means allow pex in public torrents
     "peer-port"                | number     port number
     "peer-port-random-on-start"| boolean    true means pick a random peer port on launch
     "port-forwarding-enabled"  | boolean    true means enabled
     "rpc-version"              | number     the current RPC API version
     "rpc-version-minimum"      | number     the minimum RPC API version supported
     "seedRatioLimit"           | double     the default seed ratio for torrents to use
     "seedRatioLimited"         | boolean    true if seedRatioLimit is honored by default
     "speed-limit-down"         | number     max global download speed (in K/s)
     "speed-limit-down-enabled" | boolean    true means enabled
     "speed-limit-up"           | number     max global upload speed (in K/s)
     "speed-limit-up-enabled"   | boolean    true means enabled
     "version"                  | string     long version string "$version ($revision)"

     "rpc-version" indicates the RPC interface version supported by the RPC server.
     It is incremented when a new version of Transmission changes the RPC interface.

     "rpc-version-minimum" indicates the oldest API supported by the RPC server.
     It is changes when a new version of Transmission changes the RPC interface
     in a way that is not backwards compatible.  There are no plans for this
     to be common behavior.
   */

  Map getSession() => JSON.decode(this.sendCommand("session-get",new Map()));

  /*
    DESCRIPTION: set session parameters
    PARAMETERS:
    RETURN:
      - String -> response from the server
  */

  //Session arguments

  /*
         string                     | value type & description
     ---------------------------+-------------------------------------------------
     "alt-speed-down"           | number     max global download speed (in K/s)
     "alt-speed-enabled"        | boolean    true means use the alt speeds
     "alt-speed-time-begin"     | number     when to turn on alt speeds (units: minutes after midnight)
     "alt-speed-time-enabled"   | boolean    true means the scheduled on/off times are used
     "alt-speed-time-end"       | number     when to turn off alt speeds (units: same)
     "alt-speed-time-day"       | number     what day(s) to turn on alt speeds (look at tr_sched_day)
     "alt-speed-up"             | number     max global upload speed (in K/s)
     "blocklist-enabled"        | boolean    true means enabled
     "blocklist-size"           | number     number of rules in the blocklist
     "dht-enabled"              | boolean    true means allow dht in public torrents
     "encryption"               | string     "required", "preferred", "tolerated"
     "download-dir"             | string     default path to download torrents
     "peer-limit-global"        | number     maximum global number of peers
     "peer-limit-per-torrent"   | number     maximum global number of peers
     "pex-enabled"              | boolean    true means allow pex in public torrents
     "peer-port"                | number     port number
     "peer-port-random-on-start"| boolean    true means pick a random peer port on launch
     "port-forwarding-enabled"  | boolean    true means enabled
     "rpc-version"              | number     the current RPC API version
     "rpc-version-minimum"      | number     the minimum RPC API version supported
     "seedRatioLimit"           | double     the default seed ratio for torrents to use
     "seedRatioLimited"         | boolean    true if seedRatioLimit is honored by default
     "speed-limit-down"         | number     max global download speed (in K/s)
     "speed-limit-down-enabled" | boolean    true means enabled
     "speed-limit-up"           | number     max global upload speed (in K/s)
     "speed-limit-up-enabled"   | boolean    true means enabled
     "version"                  | string     long version string "$version ($revision)"

     "rpc-version" indicates the RPC interface version supported by the RPC server.
     It is incremented when a new version of Transmission changes the RPC interface.

     "rpc-version-minimum" indicates the oldest API supported by the RPC server.
     It is changes when a new version of Transmission changes the RPC interface
     in a way that is not backwards compatible.  There are no plans for this
     to be common behavior.
   */

  String setSession(Map arguments)=> this.sendCommand("session-set",arguments);

  /*
    DESCRIPTION: get session stats
    PARAMETERS:
    RETURN:
      - Map -> response from the server
  */

  //Session stats arguments
  /*
  string                     | value type
  ---------------------------+-------------------------------------------------
  "activeTorrentCount"       | number
  "downloadSpeed"            | number
  "pausedTorrentCount"       | number
  "torrentCount"             | number
  "uploadSpeed"              | number
  ---------------------------+-------------------------------+
  "cumulative-stats"         | object, containing:           |
                             +------------------+------------+
                             | uploadedBytes    | number     | tr_session_stats
                             | downloadedBytes  | number     | tr_session_stats
                             | filesAdded       | number     | tr_session_stats
                             | sessionCount     | number     | tr_session_stats
                             | secondsActive    | number     | tr_session_stats
  ---------------------------+-------------------------------+
  "current-stats"            | object, containing:           |
                             +------------------+------------+
                             | uploadedBytes    | number     | tr_session_stats
                             | downloadedBytes  | number     | tr_session_stats
                             | filesAdded       | number     | tr_session_stats
                             | sessionCount     | number     | tr_session_stats
                             | secondsActive    | number     | tr_session_stats
   */

  Map sessionStats(){
    return JSON.decode(this.sendCommand("session-stats",new Map()));
  }

  /*
    DESCRIPTION: port checking
    PARAMETERS:
    RETURN:
      - bool -> if true is open
  */

  bool portChecking(){
    Map response = JSON.decode(this.sendCommand("port-test",new Map()));
    return response["arguments"]["port-is-open"];
  }

  /*
    DESCRIPTION: get block list
    PARAMETERS:
    RETURN:
      - int -> response from the server
  */

  int blockList(){
    Map response = JSON.decode(this.sendCommand("blocklist-update",new Map()));
    return response["arguments"]["blocklist-update"];
  }

  /*
    DESCRIPTION: set a new location for a torrent
    PARAMETERS:
      - List <int> ids -> torrents to be set
      - String location -> path of the new location
      - bool move -> move files to the new location
    RETURN:
      - int -> response from the server
  */

  String setTorrentLocation(List<int>ids, String location, bool move){
    Map arguments = new Map();
    if(!ids.isEmpty){
      arguments["ids"] = ids;
    }
    arguments["location"] = location;
    arguments["move"] = move;
    return this.sendCommand("torrent-set-location",arguments);
  }


}



