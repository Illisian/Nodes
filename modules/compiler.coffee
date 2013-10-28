Promise = require "bluebird";

Module = require "../lib/module";
util = require "util"

fs = require "fs";
coffee = require "coffee-script"
paths = require "path";
cacheStore = require "../lib/cacheStore";
class Compiler extends Module

  onSiteLoad: (req, res, site) =>
    return new Promise (resolve, reject) =>
      site.controls = new cacheStore();
      resolve();

  onSiteRequestStart: (req, res, site) =>
    return new Promise (resolve, reject) =>
      path = req._parsedUrl.pathname
      if path.match('.coffee$')
        file = paths.join @site.staticPath, req._parsedUrl.pathname;
        @log "Illisian - Compiler Module - found coffee file", file
        return @site.controls.get("compiled", file).then (compiledFile) =>
          @log "Illisian - Compiler Module - sent cached copy", file
          res.send compiledFile;
        , () => 
          @log "Illisian - Compiler Module - cached copy not found", file
          return @site.controls.getFile(file).then (fileData) =>
            @log "Illisian - Compiler Module - file cached - compile with coffee", file
            try
              compiledFile = coffee.compile fileData, {filename: file}
            catch err
              @log "Compiler", err;
            @log "Illisian - Compiler Module - file compiled", file
            return @site.controls.put("compiled", file, compiledFile).then () =>
              res.send compiledFile
              
          #rejected
      else
        resolve();


module.exports = Compiler;