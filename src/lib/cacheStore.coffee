Promise = require "bluebird"
fs = require "fs";
class CacheStore
  constructor: (@options) ->
    @library = {};
    
  get: (key, param) =>
    return new Promise (resolve, reject) =>
      if not param? and not key?
        return reject();
      if not @library[key]? 
        return reject();
      if not @library[key][param]?
        return reject();
      return resolve(@library[key][param]);

  put: (key, param, object) =>
    return new Promise (resolve, reject) =>
      if not @library[key]?
        @library[key] = {};
      if param? and object?
        @library[key][param] = object
      return resolve();
  
  keyExists: (key) =>
    return @library[key]?;
  
  paramExists: (key, param) =>
    if @keyExists(key)
      return @library[key][param]?
    return false;
    
  getFile: (filename, donotcache = false, key = 'files') =>
    return new Promise (resolve, reject) =>
      if donotcache
        return @readFile(filename, donotcache).then(resolve, reject);
      else 
        return @get(filename, "data").then (file) =>
          return resolve(file);
        , () =>
          return @readFile(filename, donotcache).then(resolve, reject);

  readFile: (filename, donotcache = false) =>
    return new Promise (resolve, reject) =>
      return fs.exists file, (result) =>
        if not result
          return reject();
        return fs.readFile filename, 'utf8', (err, data) =>
          if err?
            return reject(err);
          if donotcache
            return resolve(data);
          return @put(filename, "data", data).then =>
            return resolve(data);
        
module.exports = CacheStore