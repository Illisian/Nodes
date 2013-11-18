Promise = require "bluebird"
fs = require "fs";
class CacheStore
  constructor: (@options) ->
    @expires = {}
    @library = {};
    
  get: (key, param) =>
    return new Promise (resolve, reject) =>
      if not param? and not key?
        return reject();
      if not @library[key]? 
        return reject();
      if not @library[key][param]?
        return reject();
      
      if @expires[key]?
        if @expires[key].timeToExpire?
          if @expires[key].timeToExpire < new Date() 
            delete @library[key];
            return reject();
        else if @expires[key][param]?
          if @expires[key][param].timeToExpire?
            if @expires[key][param].timeToExpire < new Date() 
              delete @library[key];
              return reject();
              
      return resolve(@library[key][param]);

  checkExpire: (key, param, element) =>
    return new Promise (resolve, reject) =>
      if element.timeToExpire?
        if element.timeToExpire < new Date()
          return reject()
      if element.refreshOnAccess?
        expire = new Date();
        expire.setSeconds(expire.getSeconds() + element.refreshOnAccess);
        if @expires[key]?
          if @expires[key][param]?
            @expires[key][param].timeToExpire = expire;
          else 
            @expires[key].timeToExpire = expire;
      return resolve();
    
  put: (key, param, object) =>
    return new Promise (resolve, reject) =>
      if not @library[key]?
        @library[key] = {};
      if param? and object?
        @library[key][param] = object
      
      if @options.timeToLive?
        if not @expires[key]?
          @expires[key] = {}
        if not @expires[key][param]?
          @expires[key][param] = {}
          expire = new Date();
          expire.setSeconds(expire.getSeconds() + element.refreshOnAccess);
          
          @expire[key][param].timeTi
          
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