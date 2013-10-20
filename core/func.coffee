fs = require "fs"
Promise = require "bluebird"
util = require "util"
class Util
  constructor: () ->

  @unlink: (path) ->
    return new Promise (resolve, reject) ->
      fs.unlink path, (err) ->
        resolve();
  @freeforall: (path) ->
    return new Promise (resolve, reject) ->
      setTimeout () ->
        fs.chmod path, 0x777, () ->
          resolve();
      , 2000
  @log: () ->
    #console.log "[#{new Date().toUTCString()}]", arguments;
  @objToArr: (obj) ->
    result = []
    for i in [1..arguments.length]
      if obj[arguments[i]]
        result.push obj[arguments[i]];
    return result;

  @fireFunctions: (i, array, nameOfFunc, success, failure) =>
    if array[i]?
      if array[i][nameOfFunc]?
        array[i][nameOfFunc] () =>
          Util.fireFunctions(i+1, array, nameOfFunc, success, failure);
        , (errorMessage) =>
          failure(errorMessage);
          return;
      else 
        Util.fireFunctions(i+1, array, nameOfFunc, success, failure);
    else
      success();
  @firePromises: (i, array, nameOfFunc) =>
    return new Promise (resolve, reject) =>
      if array? and array.length > 0 and array[i]?
        if array[i][nameOfFunc]?
          Util.log "Firing func #{nameOfFunc}";
          return array[i][nameOfFunc]().then () =>
            return Util.firePromises(i+1, array, nameOfFunc).then(resolve, reject);
          , reject
        else 
          return Util.firePromises(i+1, array, nameOfFunc).then(resolve, reject);
      else
        return resolve();
  
module.exports = Util;
