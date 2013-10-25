func = require "./func";
Promise = require "bluebird"

class Cache
  
  constructor: (@core) ->
    {@log} = @core;
    @controls = [];
    @apps = [];
    @sites = [];
    
  getControlAsync: (path) =>
    return new Promise (resolve, reject) =>
      result = @getControl(path);
      resolve(result);
    .catch (err) => 
      @log "Cache - GetControl Error - #{path}", err, err.stack
  getControl: (path) =>
    if @controls[path]?
      return @controls[path];
    mod = require(path)
    @controls[path] = mod;
    return mod;
    
module.exports = Cache