Transmission_RCP
================

Implementation of the transmission rpc protocol in dart.

1.  Introduction

   This document describes a protocol for interacting with Transmission
   sessions remotely. Also describes the equivalent function in the dart lib.

1.1  Terminology

   The JSON terminology in RFC 4627 is used.

   In benc terms, a JSON "array" is equivalent to a benc list,
   a JSON "object" is equivalent to a benc dictionary,
   and a JSON object's "keys" are the dictionary's string keys.

2.  Message Format

   Messages are formatted as objects.  There are two types:
   requests (described in 2.1) and responses (described in 2.2).

   All text MUST be UTF-8 encoded.

2.1.  Requests

   Requests support three keys:

   (1) A required "method" string telling the name of the method to invoke
   (2) An optional "arguments" object of key/value pairs
   (3) An optional "tag" number used by clients to track responses.
       If provided by a request, the response MUST include the same tag.

2.2.  Responses

   Reponses support three keys:

   (1) A required "result" string whose value MUST be "success" on success,
       or an error string on failure.
   (2) An optional "arguments" object of key/value pairs
   (3) An optional "tag" number as described in 2.1.

2.3.  Transport Mechanism

   HTTP POSTing a JSON-encoded request is the preferred way of communicating
   with a Transmission RPC server.  The current Transmission implementation
   has the default URL as http://host:9091/transmission/rpc.  Clients
   may use this as a default, but should allow the URL to be reconfigured,
   since the port and path may be changed to allow mapping and/or multiple
   daemons to run on a single server.

   In addition to POSTing, there's also a simple notation for sending
   requests in the query portion of a URL.  This is not as robust, but can
   be useful for debugging and simple tasks.  The notation works as follows:

   (1) Any key not "tag" or "method" is treated as an argument.
   (2) The "arguments" key isn't needed, since data isn't nested.
   (3) If the value in a key/value pair can be parsed as a number, then it is.
       Otherwise if it can be parsed as an array of numbers, then it is.
       Otherwise, it's parsed as a string.

   Examples:
   ?method=torrent-start&ids=1,2
   ?method=session-set&speed-limit-down=50&speed-limit-down-enabled=1
   
2.4.  Transmission constructor

  Transmission(String host, {String port, String user, String password})
  The only requiere parameter is the host direction with out "http://". In that case the lib takes the default PORT   9091 and a no user and password required. Is possible to set all parameters.

3.  Torrent Requests

3.1.  Torrent Action Requests


   Method name          | libtransmission function | darttransmission function       
   -------------------- | ------------------------ | --------------------------------
   "torrent-start"      | tr_torrentStart          | startTorrent(List<int>ids)      
   "torrent-stop"       | tr_torrentStop           | pauseTorrent(List<int>ids)      
   "torrent-verify"     | tr_torrentVerify         | verifyTorrent(List<int>ids)     
   "torrent-reannounce" | tr_torrentManualUpdate   | reannounceTorrent(List<int>ids)  

   Request arguments: "ids", which specifies which torrents to use.
                      All torrents are used if the "ids" argument is omitted.
                      "ids" should be one of the following:
                      (1) an integer referring to a torrent id
                      (2) a list of torrent id numbers, sha1 hash strings, or both
                      (3) a string, "recently-active", for recently-active torrents

   Response arguments: none

3.2.  Torrent Mutators

   Method name: "torrent-set" --> setTorrent(List<int>ids, Map arguments)

   Request arguments:

   string                            | value type & description
   --------------------------------- | ------------------------------------------------
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

   Response arguments: none

3.3.  Torrent Accessors

   Method name: "torrent-get  |           darttransmission funtion
   -------------------------- | --------------------------------------------------
                              |      1.  getTorrent(List<int>ids, List<String> fields)
                              |      2.  getDowloadingTorrents(List<String> fields)
                              |      3.  getDownloadingWaitTorrents(List<String> fields)
                              |      4.  getSendingTorrents(List<String> fields)
                              |      5.  getSendingWaitTorrents(List<String> fields)
                              |      6.  getCheckingTorrents(List<String> fields)
                              |      7.  getCheckingWaitTorrents(List<String> fields)
                              |      8.  getPauseTorrents(List<String> fields)
                                    

   Request arguments:

   (1) An opional "ids" array as described in 3.1.
   (2) A required "fields" array of keys. (see list below)

   Response arguments:

   (1) A "torrents" array of objects, each of which contains
       the key/value pairs matching the request's "fields" argument.
   (2) If the request's "ids" field was "recently-active",
       a "removed" array of torrent-id numbers of recently-removed
       torrents.

   key                             | type                        | source 
   ------------------------------- | --------------------------- | --------
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
   ---------------------- | ------ | --------------------------- | 
   files                  | array of objects, each containing:   |
                          | ----------------------- | ---------- | 
                          | key                     | type       |
                          | bytesCompleted          | number     | tr_torrent
                          | length                  | number     | tr_info
                          | name                    | string     | tr_info
   ---------------------- | ------------------------------------ |
   fileStats              | a file's non-constant properties.    |
                          | array of tr_info.filecount objects,  |
                          | each containing:                     |
                          | ----------------------- | ---------- |
                          | bytesCompleted          | number     | tr_torrent
                          | wanted                  | boolean    | tr_info
                          | priority                | number     | tr_info
   ---------------------- | ------------------------------------ |
   peers                  | array of objects, each containing:   |
                          | ----------------------- | ---------- |
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
   ---------------------- | ------------------------------------ |
   peersFrom              | an object containing:                |
                          | ----------------------- | ---------- |
                          | fromCache               | number     | tr_stat
                          | fromIncoming            | number     | tr_stat
                          | fromPex                 | number     | tr_stat
                          | fromTracker             | number     | tr_stat
   ---------------------- | ------------------------------------ |
   pieces                 | A bitfield holding pieceCount flags  | tr_torrent
                          | which are set to 'true' if we have   |
                          | the piece matching that position.    |
                          | JSON doesn't allow raw binary data,  |
                          | so this is a base64-encoded string.  |
   ---------------------- | ------------------------------------ |
   priorities             | an array of tr_info.filecount        | tr_info
                          | numbers. each is the tr_priority_t   |
                          | mode for the corresponding file.     |
   ---------------------- | ------------------------------------ |
   trackers               | array of objects, each containing:   |
                          | ----------------------- | ---------- |
                          | announce                | string     | tr_info
                          | scrape                  | string     | tr_info
                          | tier                    | number     | tr_info
   ---------------------- | ------------------------------------ |
   wanted                 | an array of tr_info.fileCount        | tr_info
                          | 'booleans' true if the corresponding |
                          | file is to be downloaded.            |
   ---------------------- | ------------------------------------ |
   webseeds               | an array of strings:                 |
                          | ----------------------- | ---------- |
                          | webseed                 | string     | tr_info
                          | ----------------------- | ---------- |

   Example:

   Say we want to get the name and total size of torrents #7 and #10.

   Request: 

      {
         "arguments": {
             "fields": [ "id", "name", "totalSize" ],
             "ids": [ 7, 10 ]
         },
         "method": "torrent-get",
         "tag": 39693
      }


   Response:

      {
         "arguments": {
            "torrents": [ 
               { 
                   "id": 10,
                   "name": "Fedora x86_64 DVD",
                   "totalSize", 34983493932,
               },
               {
                   "id": 7,
                   "name": "Ubuntu x86_64 DVD",
                   "totalSize", 9923890123,
               } 
            ]
         },
         "result": "success",
         "tag": 39693
      }

3.4.  Adding a Torrent

   Method name: "torrent-add" |           darttransmission funtion
   -------------------------- | --------------------------------------------------
                              |
                              |      1.  addTorrent(String url, [Map args])
                              |      2.  addTorrents(List<String> urls)
                              |      

   Request arguments:

   key                | value type & description
   ------------------ | -------------------------------------------------
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

   Either "filename" OR "metainfo" MUST be included.
   All other arguments are optional.

   Response arguments: on success, a "torrent-added" object in the
                       form of one of 3.3's tr_info objects with the
                       fields for id, name, and hashString.

3.5.  Removing a Torrent

   Method name: "torrent-remove" |           darttransmission funtion
      -------------------------- | --------------------------------------------------
                                 |   removeTorrent(List<int> ids, [bool deleteLocalData = false])

   Request arguments:

   string                     | value type & description
   -------------------------- | -------------------------------------------------
   "ids"                      | array      torrent list, as described in 3.1
   "delete-local-data"        | boolean    delete local data. (default: false)

   Response arguments: none


3.6.  Moving a Torrent

   Method name: "torrent-set-location" --> setTorrentLocation(List<int>ids, String location, bool move)

   Request arguments:

   string                     | value type & description
   -------------------------- | -------------------------------------------------
   "ids"                      | array      torrent list, as described in 3.1
   "location"                 | string     the new torrent location
   "move"                     | boolean    if true, move from previous location.
                              |            otherwise, search "location" for files

   Response arguments: none


4.   Session Requests

4.1.  Session Arguments

   string                     | value type & description
   -------------------------- | -------------------------------------------------
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

4.1.1.  Mutators

   Method name: "session-set" --> setSession(Map arguments)
   Request arguments: one or more of 4.1's arguments, except: "blocklist-size",
                      "rpc-version", "rpc-version-minimum", and "version"
   Response arguments: none

4.1.2.  Accessors

   Method name: "session-get" --> getSession()
   Request arguments: none
   Response arguments: all of 4.1's arguments

4.2.  Session Statistics

   Method name: "session-stats" --> sessionStats()

   Request arguments: none

   Response arguments:

   string                     | value type
   -------------------------- | -------------------------------------------------
   "activeTorrentCount"       | number
   "downloadSpeed"            | number
   "pausedTorrentCount"       | number
   "torrentCount"             | number
   "uploadSpeed"              | number
   -------------------------- | ----------------------------- |
   "cumulative-stats"         | object, containing:           |
                              | ---------------- | ---------- |
                              | uploadedBytes    | number     | tr_session_stats
                              | downloadedBytes  | number     | tr_session_stats
                              | filesAdded       | number     | tr_session_stats
                              | sessionCount     | number     | tr_session_stats
                              | secondsActive    | number     | tr_session_stats
   -------------------------- | ----------------------------- |
   "current-stats"            | object, containing:           |
                              | ---------------- | ---------- |
                              | uploadedBytes    | number     | tr_session_stats
                              | downloadedBytes  | number     | tr_session_stats
                              | filesAdded       | number     | tr_session_stats
                              | sessionCount     | number     | tr_session_stats
                              | secondsActive    | number     | tr_session_stats

4.3.  Blocklist --> blockList()

   Method name: "blocklist-update"
   Request arguments: none
   Response arguments: a number "blocklist-size"

4.4.  Port Checking --> portChecking()

   This method tests to see if your incoming peer port is accessible
   from the outside world.

   Method name: "port-test"
   Request arguments: none
   Response arguments: a bool, "port-is-open"

 
