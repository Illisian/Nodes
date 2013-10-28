Promise = require "bluebird"
fs = require "fs";
class CacheStore
  constructor: () ->
    @library = {};
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
  
  getFile: (filename, key = 'files') =>
    return new Promise (resolve, reject) =>
      return @get(key, filename).then (file) =>
        #success
        return resolve(file);
      , () =>
        #rejected
        return fs.readFile filename, 'utf8', (err, data) =>
          if err?
            return reject(err);
          @put(key, filename, data).then =>
            return resolve(data);
module.exports = CacheStore