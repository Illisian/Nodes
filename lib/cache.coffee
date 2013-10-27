func = require "./func";
Promise = require "bluebird"
fs = require "fs";
class Cache
  
  constructor: (core) ->
    {@log} = core;
    @controls = [];
    @apps = [];
    @sites = [];
    @library = {};
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
  get: (lib, name) =>
    return new Promise (resolve, reject) =>
      if not @library[lib]?
        return reject();
      if not name?
        return resolve(@library[lib]);
      if not @library[lib][name]?
        return reject();
      return resolve(@library[lib][name]);
  put: (lib, name, object) =>
    return new Promise (resolve, reject) =>
      if not @library[lib]?
        @library[lib] = {};
      if name? and object?
        @library[lib][name] = object
      return resolve();
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