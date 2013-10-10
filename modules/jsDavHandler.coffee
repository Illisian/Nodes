extend = require "extend";
jsDAV = require "jsDAV/lib/jsdav"
jsDAV_Locks_Backend_FS = require "jsDAV/lib/DAV/plugins/locks/fs";

class jsDavHandler
  constructor: (@path = "", @locks = "") ->

    
  init: () =>
    @server = jsDAV.mount({
      server: {},
      standalone: false,
      mount: "",
      node: @path,
      locksBackend: jsDAV_Locks_Backend_FS.new(@locks)
    });
  processRequest: (req, res, next) =>
    #console.log "JsDavHandler - process request";
    @server.exec(req,res);

module.exports = jsDavHandler;