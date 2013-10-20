Promise = require "bluebird";
util = require "util"
class Security
  constructor: (@renderer) ->
    
  onSiteRequestStart: () =>
    return new Promise (resolve, reject) =>
      @log "SECURITY1 LOAD";
      resolve();


#  onControlProcessed: (control) =>
#    return new Promise (resolve, reject) =>
#      resolve();
      
  onPageFinish: () =>
    return new Promise (resolve, reject) =>
      @log "SECURITY1 KILL";
      resolve();

module.exports = Security;