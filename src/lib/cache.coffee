func = require "./func";
cacheStore = require "./cacheStore";
Promise = require "bluebird"
fs = require "fs";


class Cache
  
  constructor: (core) ->
    {@log} = core;
    @controls = [];
    @apps = [];
    @sites = new cacheStore;
    
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
  
  getFile: (filename) =>
    return new Promise (resolve, reject) =>
      return @get("files", filename).then (file) =>
        #success
        return resolve(file);
      , () =>
        #rejected
        return fs.readFile filename, 'utf8', (err, data) =>
          if err?
            return reject(err);
          @put("files", filename, data).then =>
            return resolve(data);
        
      
      
module.exports = Cache