fs = require "fs"
Promise = require "bluebird"
util = require "util"
url = require 'url'
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
    console.log "[#{new Date().toUTCString()}]", arguments;
  @objToArr: (obj) ->
    result = []
    for i in [1..arguments.length]
      if obj[arguments[i]]
        result.push obj[arguments[i]];
    return result;
  @findCookieKey: (req, key = 'connect.sid') ->
    return (req.secureCookies && req.secureCookies[key]) || (req.signedCookies && req.signedCookies[key]) || (req.cookies && req.cookies[key]);
  @getUriFromReq: (req) ->
    return url.parse "http://#{req.headers.host}#{req._parsedUrl.pathname}";
  @firePromises: (i, array, nameOfFunc, args) =>
    return new Promise (resolve, reject) =>
      if array? and array.length > 0 and array[i]?
        if nameOfFunc?
          if array[i][nameOfFunc]?
            Util.log "Firing func #{nameOfFunc}";
            return array[i][nameOfFunc](args).then () =>
              return Util.firePromises(i+1, array, nameOfFunc).then(resolve, reject);
            , reject
          else 
            return Util.firePromises(i+1, array, nameOfFunc).then(resolve, reject);
        else
          array[i](args).then () =>
            return Util.firePromises(i+1, array, nameOfFunc).then(resolve, reject);
          
      else
        return resolve();
  @isArray: Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
module.exports = Util;
